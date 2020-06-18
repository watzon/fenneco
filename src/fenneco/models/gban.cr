class Fenneco < Proton::Client
  module Models
    class Gban < Crecto::Model
      schema "gbans" do
        field :reason,  String
        field :message, String

        belongs_to :user, User
      end
    end
  end
end
