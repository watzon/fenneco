class Fennec < Proton::Client
  @[Command(".log")]
  def log_command(ctx)
    if log_chat_id = ENV["LOG_CHAT_ID"]?
      log_chat_id = log_chat_id.to_i64
      if reply_message = ctx.message.reply_message
        forward_messages(log_chat_id, reply_message)
      else
        Utils.log(ctx.message.raw_text)
      end
    end
    delete_message(ctx.message)
  end
end
