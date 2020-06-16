class Fennec < Proton::Client
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
    delete_message(msg)

    user_count = Repo.aggregate(Models::User, :count, :id)
    chat_count = Repo.aggregate(Models::Chat, :count, :id)
    gbanned_users = Repo.aggregate(Models::Gban, :count, :id)

    module_count = Dir.glob("src/fennec/modules/**/*.cr").size
    uptime = HumanizeTime.distance_of_time_in_words(BOT_START_TIME, Time.utc)

    response = Utils::MarkdownBuilder.build do
      section do
        bold("Fenneco")
        key_value_item("version", code(Fennec::VERSION))
        key_value_item("git hash", code(`git rev-parse --short HEAD`.strip))
        key_value_item("repo url", link("watzon/fenneco", FENNECO_GH_URL))
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

    send_message(msg.chat_id!, response.to_s, file: "assets/fenneco.png")
  end
end
