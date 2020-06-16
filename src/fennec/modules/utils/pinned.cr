class Fennec < Proton::Client
  @[Help(
    description: "Send's 'Please read the pinned message' with a link to the pinned message",
    usage: ".pinned"
  )]
  @[Command(".pinned")]
  def pinned_command(ctx)
    msg = ctx.message
    pinned = TL.get_chat_pinned_message(msg.chat_id!)
    if pinned.id! > 0
      link = pinned.link
      edit_message(msg, "Please read the [pinned message](#{link})")
    end
  end
end
