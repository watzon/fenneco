class Fennec < Proton::Client
  @[Help(
    description: "Pin the replied to message",
    usage: ".pin"
  )]
  @[Command(".pin")]
  def pin_command(ctx)
    if reply_message = ctx.message.reply_message
      pin_message(ctx.message.chat_id!, reply_message)
      delete_message(ctx.message)
    else
      edit_message(ctx.message, "`Please reply to the message you want to pin`")
    end
  end
end
