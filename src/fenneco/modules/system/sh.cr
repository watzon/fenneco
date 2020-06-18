class Fenneco < Proton::Client
  @[Help(
    description: "Run a shell command on the local system",
    usage: ".sh [command]"
  )]
  @[Command([".sh", ".shell"], edited: true)]
  def shell_command(ctx)
    edit_message(ctx.message, "`Running command: #{ctx.text}`")
    stdout = IO::Memory.new
    stderr = IO::Memory.new
    status = nil

    return edit_message(ctx.message, "`No command provided`") if ctx.text.empty?

    elapsed = Time.measure do
      status = Process.run(ctx.text, shell: true, output: stdout, error: stderr)
    end

    return_code = status.not_nil!.exit_code
    result = stdout.rewind.gets_to_end.strip
    if result.empty?
      result = stderr.rewind.gets_to_end.strip
    end

    output = String.build do |str|
      str.puts "*Command:* `#{ctx.text}`"
      str.puts "--------------------------------------"
      str.puts result.empty? ? "`[no output]`" : "```\n#{result}```"
      str.puts "--------------------------------------"
      str.puts "\u{26A0} Return code: #{return_code}\n" if return_code > 0
      str.puts "\u{1F552} Run time: #{elapsed.total_seconds} seconds"
    end

    edit_message(ctx.message, output)
  end
end
