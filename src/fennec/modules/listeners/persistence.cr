class Fennec < Proton::Client
  @[Help(
    description: "Persists users and chats to the database. This is for " \
                 "gbans and yet to be created functions."
  )]
  def persistence_listener(update)
    case update
    when TL::UpdateNewMessage, TL::UpdateMessageSendSucceeded
      message = update.message!
      Utils.persist_chat(message.chat_id!)
      if message.sender_user_id
        Utils.persist_user(message.sender_user_id!)
        Utils.persist_chat_member(message.chat_id!, message.sender_user_id!)
      end
    when TL::UpdateUserChatAction
      Utils.persist_chat(update.chat_id!)
      Utils.persist_user(update.user_id!)
      Utils.persist_chat_member(update.chat_id!, update.user_id!)
    when TL::UpdateMessageEdited, TL::UpdateMessageSendAcknowledged
      Utils.persist_chat(update.chat_id!)
    when TL::UpdateUserStatus
      Utils.persist_user(update.user_id!)
    when TL::UpdateUser
      Utils.persist_user(update.user!.id!, true)
    when TL::UpdateChatTitle
      Utils.persist_chat(update.chat_id!, true)
    else
    end
  end
end
