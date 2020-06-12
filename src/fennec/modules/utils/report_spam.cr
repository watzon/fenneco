class Fennec < Proton::Client
  @[Help(
    description: "Forward the replied to message to SpamWatch",
    usage: ".spam"
  )]
  @[Command(".spam")]
  def spam_command(ctx)
    forward_messages(-1001312712379, [{ctx.message.chat_id, ctx.message.reply_to_message_id}])
    delete_messages(ctx.message.chat_id, [ctx.message])
  end
end
