require "icr"

class Fennec < Proton::Client
  class_getter! icr_command_stack : Icr::CommandStack?
  class_getter! icr_executor : Icr::Executer?

  @[Help(
    description: "Compile the given text as Crystal code using ICR. Maintains a code history.",
    args: {
      reset: "reset the code history and start over",
    },
    usage: ".eval [args] <code>"
  )]
  @[Command([".eval", ".exec"])]
  def eval_command(ctx)
    msg = ctx.message
    text = ctx.text.to_s

    @@icr_command_stack ||= Icr::CommandStack.new
    @@icr_executor ||= Icr::Executer.new(self.class.icr_command_stack, false)

    if text.strip.starts_with?("reset")
      self.class.icr_command_stack.clear
      return edit_message(msg, "`Crystal execution history reset!`")
    end

    edit_message(msg, "`Evaluating Crystal...`")
    command = text.strip.gsub(/\b__\b/) { self.class.icr_executor.execute.value.to_s.strip }

    output, value, error = {"", "", true}

    elapsed = Time.measure do
      result = check_crystal_syntax(command)
      begin
        output, value, error = process_crystal_execution_result(result, command)
      rescue ex
        output, value, error = ex.message.to_s, "", true
      end
    end

    if !value.empty? && value.size > 2000
      value_link = Utils.paste(value)
    end

    if output && !output.empty? && output.size > 2000
      output_link = Utils.paste(output)
    end

    response = Utils::MarkdownBuilder.build do
      section(indent: 0) do
        bold("Input (crystal)")
        pre(command, language: "crystal")
        if error
          bold("Error")
          pre(output.to_s)
        else
          bold("Result")
          if value_link
            link("paste bin link", value_link)
            text("\n")
          else
            pre(value.empty? ? "[no result]" : value)
          end

          bold("Output")
          if output_link
            link("paste bin link", output_link)
          else
            pre(output.to_s.empty? ? "[no output]" : output)
          end
        end
      end
    end

    edit_message(msg, response.to_s)
  end

  private def process_crystal_execution_result(result, command)
    case result.status
    when :ok
      self.class.icr_command_stack.push(command)
      output, value = execute_crystal
      {output, value, false}
    when :unexpected_eof
      {"Unexpected EOF", "", true}
    when :unterminated_literal
      {"Unterminated Literal", "", true}
    when :error
      # Give it the second try, validate the command in scope of entire file
      self.class.icr_command_stack.push(command)
      entire_file_result = check_crystal_syntax(self.class.icr_command_stack.to_code)
      case entire_file_result.status
      when :ok
        output, value = execute_crystal
        {output, value, false}
      when :unexpected_eof
        self.class.icr_command_stack.pop
        process_crystal_execution_result(entire_file_result, command)
      else
        self.class.icr_command_stack.pop
        response = result.error_message
        {response, "", true}
      end
    else
      {"Unknown SyntaxCheckResult status: #{result.status}", "", true}
    end
  end

  private def execute_crystal
    result = self.class.icr_executor.execute
    if result.success?
      if self.class.icr_command_stack.commands.last.type == :regular
        {result.output, "#{result.value}"}
      else
        {result.output, "ok"}
      end
    else
      {result.error_output, ""}
    end
  end

  private def check_crystal_syntax(code)
    Crystal::Parser.parse(code)
    Icr::SyntaxCheckResult.new(:ok)
  rescue err : Crystal::SyntaxException
    case err.message.to_s
    when .includes?("EOF")
      Icr::SyntaxCheckResult.new(:unexpected_eof)
    when .includes?("unterminated char literal")
      # catches error for 'aa' and returns compiler error
      Icr::SyntaxCheckResult.new(:ok)
    when .includes?("unterminated")
      # catches unterminated hashes and arrays
      Icr::SyntaxCheckResult.new(:unterminated_literal)
    else
      Icr::SyntaxCheckResult.new(:error, err.message.to_s)
    end
  end
end
