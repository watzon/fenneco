class Fennec < Proton::Client
  @[Command(".eval")]
  def eval_command(ctx)
    code = ctx.text
    edit_message(ctx.message, "`Compiling and executing Crystal...`")
    response = execute_crystal(code)
    edit_message(ctx.message, response.to_s)
  end

  private def execute_crystal(code, args = nil)
    binary, error = compile_to_file(code)

    if error.empty?
      max_wait = 30.seconds
      stdout = IO::Memory.new
      stderr = IO::Memory.new

      status_channel = Channel(Process::Status).new(1)
      exit_code = 0
      elapsed = Time.measure do
        spawn do
          status_channel.send Process.run(binary, args: args, output: stdout, error: stderr, shell: true)
        end

        select
        when status = status_channel.receive
          exit_code = status.exit_code
        when timeout max_wait
          exit_code = 124
        end
      end

      result = stdout.rewind.gets_to_end.strip
      if result.empty?
        result = stderr.rewind.gets_to_end.strip
      end
    else
      result = error
      exit_code = 1
      elapsed = 0.seconds
    end

    Utils::MarkdownBuilder.build do
      section(indent: 0) do
        text("")
        sub_section(indent: 0) do
          bold("Code")
          pre(code, language: "crystal")
        end

        sub_section(indent: 0) do
          bold("Output")
          pre(result.empty? ? "[no output]" : result)
        end

        sub_section(indent: 0) do
          text("")
          text("\u{26A0} Return code: #{exit_code}\n")
          text("\u{1F552} Run time: #{elapsed.total_seconds} seconds\n")
        end
      end
    end
  end

  private def compile_to_file(code)
    tempfile = File.tempfile(nil, ".cr") do |file|
      file << code
    end

    filepath = tempfile.path
    error = IO::Memory.new
    outfile = File.join(File.dirname(filepath), File.basename(filepath, ".cr"))

    status = Process.run("crystal build #{filepath} -o #{outfile} --no-color --warnings none", error: error, shell: true)

    {outfile, error.rewind.gets_to_end}
  end
end
