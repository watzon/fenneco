class Fenneco < Proton::Client
  module Models
    class ChatSettings < Crecto::Model
      schema "chat_settings" do
        field :gbans,         Bool,   default: false
        field :gban_command,  String, default: "/ban"
        field :fbans,         Bool,   default: false
        field :fban_command,  String, default: "/fban"

        field :welcomes,        Bool,   default: false
        field :welcome_message, String, default: nil
        field :welcome_delay,   String, default: nil

        belongs_to :chat, Chat, primary_key: true
      end
    end
  end
end
