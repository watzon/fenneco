require "icr"

class Fennec < Proton::Client
  class_getter! icr_command_stack : Icr::CommandStack?
  class_getter! icr_executor : Icr::Executer?

  @[Command(".eval")]
  def eval_command(ctx)
    msg = ctx.message
    args, text = Utils.parse_args(ctx.text)
    debug = args["debug"]? ? true : false

    @@icr_command_stack ||= Icr::CommandStack.new
    @@icr_executor ||= Icr::Executer.new(self.class.icr_command_stack, debug)
    self.class.icr_executor.debug = debug

    if args["reset"]?
      self.class.icr_command_stack.clear
      if text.strip.empty?
        return edit_message(msg, "`Crystal execution history reset!`")
      end
    end

    edit_message(msg, "`Evaluating Crystal...`")
    command = text.strip.gsub(/\b__\b/) { self.class.icr_executor.execute.value.to_s.strip }

    output, value, error = {"", "", true}

    elapsed = Time.measure do
      result = check_crystal_syntax(command)
      output, value, error = process_crystal_execution_result(result, command)
    end

    response = String.build do |str|
      str.puts "*Input (crystal)*"
      str.puts "```"
      str.puts command
      str.puts "```"
      str.puts "*Result*"
      str.puts "```"
      str.puts value.empty? ? "[no result]" : value
      str.puts "```"
      str.puts "*Output*"
      str.puts "```"
      str.puts output.to_s.empty? ? "[no output]" : output
      str.puts "```"
    end

    edit_message(msg, response)
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
