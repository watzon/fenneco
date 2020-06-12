require "uri"

class Fennec < Proton::Client
  @[Command(".paste")]
  def paste_command(ctx)
    msg = ctx.message
    args, text = Utils.parse_args(ctx.text)
    ext = (args["ext"]? || "txt").to_s.lstrip('.')

    if text.strip.empty? && (reply_message = msg.reply_to_message)
      text = reply_message.text.to_s
    end

    if text.strip.empty?
      return edit_message(msg, "`Please give me some text to paste`")
    end

    edit_message(msg, "`Pasting...`")

    begin
      url = Utils.paste(text)
      edit_message(ctx.message, url + ".#{ext}")
    rescue ex
      edit_message(ctx.message, "`#{ex.message}`")
    end
  end
end
