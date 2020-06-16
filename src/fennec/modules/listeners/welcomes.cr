class Fennec < Proton::Client
  @[Help(
    description: "Sends welcome messages to new users in chats that are configured for it"
  )]
  @[On(:new_chat_member)]
  def welcomes_listener(update)
    msg = update.as(TL::UpdateNewMessage).message!
    content = msg.content!
    welcomes = Utils.get_chat_setting(msg.chat_id!, "welcomes")
    if welcomes
      welcome_message = Utils.get_chat_setting(msg.chat_id!, "welcome_message").to_s
      welcome_delay = Utils.get_chat_setting(msg.chat_id!, "welcome_delay").to_s
      return if welcome_message.strip.empty?

      users = if content.responds_to?(:member_user_ids)
          content.member_user_ids!
        else
          [msg.sender_user_id!]
        end

      user = TL.get_user(users[0])
      welcome_message = welcome_message
        .gsub("{display name}", user.display_name)
        .gsub("{first name}", user.first_name!)
        .gsub("{last name}", user.last_name!)

      unless welcome_delay.strip.empty?
        if match = welcome_delay.match(/(\d+)\.\.(\d+)/)
          seconds = rand(match[1].to_i .. match[2].to_i)
          sleep seconds
        elsif seconds = welcome_delay.to_i?
          sleep seconds
        end
      end

      send_message(msg.chat_id!, welcome_message, reply_message: msg)
    end
  end
end
