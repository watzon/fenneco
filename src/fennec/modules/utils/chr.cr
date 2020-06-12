class Fennec < Proton::Client
  @[Help(
    description: "List the codepoints for the message's characters.",
    usage: ".chr <text>"
  )]
  @[Command(".chr", edited: true)]
  def codepoint_command(ctx)
    text = (msg = ctx.message.reply_to_message) ? msg.text : ctx.text
    if text
      output = String.build do |str|
        text.chars.uniq.each do |chr|
          next if chr == ' '
          str.puts "`#{chr}`" + ": " + "*0x#{chr.ord.to_s(16)}*"
        end
      end
      edit_message(ctx.message, output)
    end
  end
end
