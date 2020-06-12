class Fennec < Proton::Client
  @[Command(".info")]
  def message_info_command(ctx)
    message = ctx.message.reply_to_message_id > 0 ?
      TL.get_message(ctx.message.chat_id, ctx.message.reply_to_message_id) :
      ctx.message
    edit_message(ctx.message, "```\n" + message.to_pretty_json + "\n```")
  end
end
