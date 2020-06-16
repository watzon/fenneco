class Fennec < Proton::Client
  module Models
    class Chat < Crecto::Model
      schema "chats" do
        field :id, Int64, primary_key: true
        field :title, String
        enum_field :type, Type

        has_one :settings, ChatSettings, dependent: :destroy

        has_many :members, ChatMember
        has_many :users, User, through: :members
      end

      enum Type
        Private
        Basic
        Supergroup
        Secret

        def self.from_tl(type : TL::ChatType)
          case type
          when TL::ChatTypePrivate
            Private
          when TL::ChatTypeBasicGroup
            Basic
          when TL::ChatTypeSupergroup
            Supergroup
          when TL::ChatTypeSecret
            Secret
          else raise "Unreachable"
          end
        end
      end
    end
  end
end
