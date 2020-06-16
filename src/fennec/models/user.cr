class Fennec < Proton::Client
  module Models
    class User < Crecto::Model
      schema "users" do
        field :id,            Int32,  primary_key: true
        field :first_name,    String
        field :last_name,     String
        field :username,      String
        field :language_code, String

        has_one  :gban,        Gban
        has_many :memberships, ChatMember
        has_many :chats,       Chat,      through: :memberships
      end
    end
  end
end
