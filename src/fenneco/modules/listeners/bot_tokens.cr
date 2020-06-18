class Fenneco < Proton::Client
  @[Help(
    description: "Listens for bot tokens posted in @BotSupport and replies with a photo."
  )]
  @[OnMessage(Fenneco::Utils::BOT_TOKEN_RE, outgoing: false)]
  def bot_tokens_listener(ctx)
    msg = ctx.message
    if ctx.message.chat_id == -1001311056733
      send_message(msg.chat_id!, file: "src/fenneco/images/days-since-last-bot-token.jpg", reply_message: msg)
    end
  end
end
