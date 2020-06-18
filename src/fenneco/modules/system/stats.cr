class Fenneco < Proton::Client
  # Store the bot's start time so we can get an uptime
  BOT_START_TIME = Time.utc

  FENNECO_GH_URL = "https://github.com/watzon/fenneco"

  @[Help(
    description: "Show stats about the bot and the database",
    usage: ".stats"
  )]
  @[Command(".stats")]
  def stats_command(ctx)
    msg = ctx.message
    edit_message(msg, "`Gathering stats...`")

    user_count = Repo.aggregate(Models::User, :count, :id)
    chat_count = Repo.aggregate(Models::Chat, :count, :id)
    gbanned_users = Repo.aggregate(Models::Gban, :count, :id)

    invite_link = ENV["LOG_CHAT_INVITE_LINK"]?
    module_count = Dir.glob("src/fenneco/modules/**/*.cr").size
    uptime = HumanizeTime.distance_of_time_in_words(BOT_START_TIME, Time.utc)

    response = Utils::MarkdownBuilder.build do
      section do
        bold("Fenneco")
        key_value_item("version", code(Fenneco::VERSION))
        key_value_item("git hash", code(`git rev-parse --short HEAD`.strip))
        key_value_item("repo url", link("watzon/fenneco", FENNECO_GH_URL))
        key_value_item("log chat", link("follow", invite_link)) if invite_link
        key_value_item("uptime", code(uptime))
        key_value_item("loaded modules", code(module_count))
        sub_section do
          bold("database")
          key_value_item("user count", code(user_count))
          key_value_item("chat count", code(chat_count))
          key_value_item("gbanned users", code(gbanned_users))
        end
      end
    end

    delete_message(msg)
    send_message(msg.chat_id!, response.to_s, file: "assets/fenneco.png", reply_message: ctx.message.reply_message)
  end
end
