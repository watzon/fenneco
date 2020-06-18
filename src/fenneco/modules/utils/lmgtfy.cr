require "uri"

class Fenneco < Proton::Client
  @[Help(
    description: "Sends a 'let me google that for you' message",
    usage: ".lmgtfy <text>"
  )]
  @[Command(/\.l(mgt)?fy/)]
  def lmgtfy_command(ctx)
    msg = ctx.message
    args, text = Utils.parse_args(ctx.text)

    if text.strip.empty? && (reply_message = msg.reply_message)
      text = reply_message.text.to_s
    end

    if text.strip.empty?
      return edit_message(msg, "`Nothing to Google`")
    end

    query = URI.encode(text.strip, space_to_plus: true)
    edit_message(msg, "https://lmgtfy.com/?q=#{query}")
  end
end
