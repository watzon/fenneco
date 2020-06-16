class Fennec < Proton::Client
  BOT_TOKEN_RE = /[\d]{10}:AA[\w\d_\-]{33}/

  @[Help(
    description: "Listens for bot tokens posted in @BotSupport and replies with a photo."
  )]
  @[OnMessage(Fennec::BOT_TOKEN_RE, outgoing: false)]
  def bot_tokens_listener(ctx)
    msg = ctx.message
    if ctx.message.chat_id == -1001311056733
      send_message(msg.chat_id!, file: "src/fennec/images/days-since-last-bot-token.jpg", reply_message: msg)
    end
  end
end
