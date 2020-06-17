class Fennec < Proton::Client
  DEFAULT_GBAN_REASON = "spam[gban]"
  DEFAULT_GBAN_CHUNK_SIZE = 10

  @[Help(
    description: "Globally ban a user in all registered groups and federations",
    usage: ".gban <user>"
  )]
  @[Command(".gban")]
  def gban_command(ctx)
    msg = ctx.message
    chat = TL.get_chat(msg.chat_id!)
    args, text = ArgParser({verbose: Bool, reason: String?}).parse(ctx.text)

    edit_message(msg, "`Globally banning...`")

    if (msg.reply_to_message_id! > 0) && (user = Utils.user_from_message(msg))
      ban_reason = args[:reason] || text.empty? ? DEFAULT_GBAN_REASON : text
      single_gban(user, ban_reason, msg, args)
    else
      ents = msg.text.to_s.split(/\s+/).reject(&.empty?)
      users = Utils.users_from_entities(msg, ents)
      ban_reason = args[:reason] || DEFAULT_GBAN_REASON

      if users.empty?
        edit_message(msg, "I don't know who those users are")
      elsif users.size == 1
        user = users[0]
        single_gban(user, ban_reason, msg, args)
      else
        multi_gban(users, ban_reason, msg, args)
      end
    end
  end

  def single_gban(user, reason, message, args)
    reply_message = message.reply_message
    message_content = Utils.textify_message(reply_message) if reply_message
    status, reason = gban_user(user.id!, reason, message_content)

    if reply_message && message.chat_id! != -1001312712379
      # Forward the message to SpamWatch unless we're already there
      forward_messages(-1001312712379, reply_message)
    end

    case status
    when :new
      content = "Gbanned #{user.inline_mention}\n*Reason*: `#{reason}`"
    when :update
      content = "Updated Gban for #{user.inline_mention}\n*New Reason*: `#{reason}`"
    when :error
      content = "Failed to Gban #{user.inline_mention}\n*Reason*: `#{reason}`"
      Utils.log(content, "gban", "error")
      return delete_message(message)
    end

    if args[:verbose]
      edit_message(message, content.to_s)
    else
      delete_message(message)
    end

    log_message = Utils::MarkdownBuilder.build do
      section(indent: 0) do
        bold("#{status == :new ? "New" : "Updated"} Gban")
        key_value_item(bold("User"), "#{user.inline_mention} `(#{user.id!})`")
        key_value_item(bold(status == :new ? "Reason" : "New Reason"), code(reason))
        if message_content && !message_content.empty?
          bold("Message:")
          text("----------------------------------------")
          text(message_content)
        end
      end
    end

    Utils.log(log_message.to_s, "gban", "#{status.to_s}gban")
  end

  def multi_gban(users, reason, message, args)
    # TODO
  end

  def gban_user(user, reason, message)
    uid = user.is_a?(TL::User) ? user.id! : user

    if uid == 0
      # A user id of 0 indicates a deleted account
      return {:error, "`Deleted account`"}
    end

    if gban = Repo.get_by(Models::Gban, user_id: uid)
      # If the user is already gbanned, update the ban instead
      gban.reason = reason
      gban.message = message
      Repo.update(gban)
      return {:update, reason}
    end

    gban = Models::Gban.new
    gban.user_id = uid
    gban.reason = reason
    gban.message = message
    Repo.insert(gban)

    chat_settings_query = Crecto::Repo::Query.where(:gbans, true).or_where(:fbans, true)
    chat_settings = Repo.all(Models::ChatSettings, chat_settings_query)

    mentions = [] of TL::Message

    chat_settings.each do |set|
      begin
        cid = set.chat_id.not_nil!.to_i64

        if set.gbans == true
          if set.gban_command == "manual" || !set.gban_command
            # "manual" means that we ban without using a group management bot.
            # This is mostly for chats with no bot, but can also be used if we don't
            # want to spam chats with gban messages.
            ban_chat_member(cid, uid)
          else
            # Send a mention to the chat so that the group management bot can recognize the user
            mentions << send_message(cid, "[#{uid}](tg://user?id=#{uid})")
            send_message(cid, "#{set.gban_command} #{uid} #{reason}", parse_mode: nil)
          end
        end

        if set.fbans == true
          # Send a mention to the chat so that the group management bot can recognize the user
          mentions << send_message(cid, "[#{uid}](tg://user?id=#{uid})")
          send_message(cid, "#{set.fban_command} #{uid} #{reason}", parse_mode: nil)
        end
      rescue ex
      end
    end

    # TODO: Spamwatch integration (need admin perms anyway)

    unless mentions.empty?
      # Wait a bit before clearing mentions (to account for slow bots)
      spawn do
        sleep 5
        delete_messages(nil, mentions)
      end
    end

    {:new, reason}
  end
end
