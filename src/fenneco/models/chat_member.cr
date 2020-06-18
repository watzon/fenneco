class Fenneco < Proton::Client
  module Models
    class ChatMember < Crecto::Model
      schema "chat_members" do
        belongs_to :chat, Chat
        belongs_to :user, User
      end
    end
  end
end
