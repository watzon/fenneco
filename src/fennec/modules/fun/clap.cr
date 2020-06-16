class Fennec < Proton::Client
  @[Help(
    description: "insert 👏 a 👏 clap 👏 emoji 👏 between 👏 each 👏 word 👏 to 👏 emphasize 👏 a 👏 point",
    usage: ".clap <text>"
  )]
  @[Command(".clap", edited: true)]
  def clap_command(ctx)
    if text = (msg = ctx.message.reply_message) ? msg.text : ctx.text
      chars = text.chars.map do |char|
        next " 👏 " if char.ascii_whitespace?
        char
      end
      edit_message(ctx.message, chars.join)
    end
  end
end
