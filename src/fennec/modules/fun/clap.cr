class Fennec < Proton::Client
  @[Command(".clap", edited: true)]
  def clap_command(ctx)
    if text = (msg = ctx.message.reply_to_message) ? msg.text : ctx.text
      chars = text.chars.map do |char|
        next " 👏 " if char.ascii_whitespace?
        char
      end
      edit_message(ctx.message, chars.join)
    end
  end
end
