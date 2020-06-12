class Fennec < Proton::Client
  @[Help(
    description: "Delete messages, either using a reference message or a number.",
    usage: ".purge [count | reply message]"
  )]
  @[Command(".purge")]
  def purge_command(ctx)
    msg = ctx.message
    if reply = msg.reply_to_message
      last_message_id = reply.id
      count = 0
      loop do
        response = TL.get_chat_history(msg.chat_id, from_message_id: last_message_id, offset: -99, limit: 100, only_local: false)
        messages = response.messages
        break if messages.empty?
        delete_messages(msg.chat_id, messages)
        count += messages.size
        last_message_id = messages.last.id
        break if last_message_id == msg.id
      end
      send_message(msg.chat_id, "`Successfully deleted #{count} messages`")
    elsif count = ctx.text.to_s.to_i?
      deleted = 0
      last_message_id = msg.id
      delete_messages(msg.chat_id, [msg])
      while deleted < count
        batch_size = Math.min(count - deleted, 100)
        response = TL.get_chat_history(msg.chat_id, from_message_id: last_message_id, offset: 0, limit: batch_size, only_local: false)
        messages = response.messages
        break if messages.empty?
        delete_messages(msg.chat_id, messages)
        deleted += messages.size
        last_message_id = messages.first.id
      end
      send_message(msg.chat_id, "`Successfully deleted #{deleted} messages`")
    end
  end
end
