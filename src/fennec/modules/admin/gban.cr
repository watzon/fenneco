class Fennec < Proton::Client
  DEFAULT_GBAN_REASON = "spam[gban]"
  DEFAULT_GBAN_CHUNK_SIZE = 10

  @[Help(
    description: "Globally ban a user in all registered groups",
    usage: ".gban <user>"
  )]
  @[Command(".gban")]
  def gban_command(ctx)
    msg = ctx.message
    chat = TL.get_chat(msg.chat_id!)
    args, text = ArgParser({verbose: Bool, reason: String?}).parse(ctx.text)
    verbose = args[:verbose] || chat.private?

    edit_message(msg, "`Globally banning...`")

    if (reply_message = msg.reply_message) && (user = Utils.user_from_message(msg))
      message = Utils.textify_message(reply_message)
      ban_reason = args[:reason] || text.empty? ? DEFAULT_GBAN_REASON : text
      status, _, error = gban_user(user.id!, ban_reason, message)

      if status
        if verbose
          edit_message(msg, "Gbanned #{user.inline_mention}\nReason: *#{ban_reason}*")
        else
          delete_message(msg)
        end

        log_message = Utils::MarkdownBuilder.build do
          section(indent: 0) do
            bold("New Gban")
            key_value_item(bold("User"), "#{user.inline_mention} `(#{user.id!})`")
            key_value_item(bold("Reason"), code(ban_reason))
            bold("Message:")
            text("----------------------------------------")
            text(message)
          end
        end

        Utils.log(log_message.to_s)
      else
        delete_message(msg)
        Utils.log(error)
      end
    else
      ents = msg.text.to_s.split(/\s+/).reject(&.empty?)
      users = Utils.users_from_entities(msg, ents)
      ban_reason = args[:reason] || DEFAULT_GBAN_REASON

      if users.empty?
        edit_message(msg, "I don't know who those users are")
      elsif users.size == 1
        user = users[0]
        status, _, error = gban_user(user.id!, ban_reason, nil)

        if status
          if verbose
            edit_message(msg, "Gbanned #{user.inline_mention}\nReason: *#{ban_reason}*")
          else
            delete_message(msg)
          end

          log_message = Utils::MarkdownBuilder.build do
            section(indent: 0) do
              bold("New Gban")
              key_value_item(bold("User"), "#{user.inline_mention} `(#{user.id!})`")
              key_value_item(bold("Reason"), code(ban_reason))
            end
          end

          Utils.log(log_message.to_s)
        else
          delete_message(msg)
          Utils.log(error)
        end
      else
        # TODO
      end
    end
  end

  def gban_user(user, reason, message)
    uid = user.is_a?(TL::User) ? user.id! : user

    # A user id of 0 indicates a deleted account
    if uid == 0
      return {false, 0, "`Deleted account`"}
    end

    # If the user is already gbanned, update the ban instead
    if gban = Repo.get_by(Models::Gban, user_id: uid)
      gban.reason = reason
      gban.message = message
      Repo.update(gban)
      return {true, 1, reason}
    end

    gban = Models::Gban.new
    gban.user_id = uid
    gban.reason = reason
    gban.message = message
    Repo.insert(gban)

    chat_settings_query = Crecto::Repo::Query.where(:gbans, true)
    chat_settings = Repo.all(Models::ChatSettings, chat_settings_query)

    count = 0
    mentions = [] of TL::Message

    chat_settings.each do |set|
      begin
        cid = set.chat_id.not_nil!.to_i64
        if set.gban_command == "manual" || !set.gban_command
          ban_chat_member(cid, uid)
        else
          mentions << send_message(cid, "[#{uid}](tg://user?id=#{uid})")
          send_message(cid, "#{set.gban_command} #{uid} #{reason}", parse_mode: nil)
        end
        count += 1
      rescue ex
      end
    end

    # TODO: Spamwatch integration (need admin perms anyway)

    # Wait a bit before clearing mentions
    spawn do
      sleep 10
      delete_messages(nil, mentions)
    end

    {true, count, reason}
  end
end
