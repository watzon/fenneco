class Fennec < Proton::Client
  @[Command([".u", ".user"])]
  def user_info_command(ctx)
    msg = ctx.message
    args, text = Utils.parse_args(ctx.text)
    ents = text.to_s.split(/\s+/).reject(&.empty?)

    spawn edit_message(msg, "`Please wait... Resolving entities.`")

    if ents.empty? && msg.reply?
      response = info_from_reply(msg, args)
    else
      response = info_from_arguments(msg, ents, args)
    end

    if response
      edit_message(msg, response.to_s)
    else
      edit_message(msg, "`Failed to resolve the given entities`")
    end
  end

  private def info_from_arguments(msg, ents, args)
    text_entities = msg.text_entities.keys.map(&.type).select(&.is_a?(TL::TextEntityTypeMentionName))
    uids = text_entities.map(&.as(TL::TextEntityTypeMentionName).user_id)

    # Map over the given entities. They could be ids, usernames, or garbage text.
    # We need to resolve them if possible and add them to an array.
    users = (ents + uids).reduce([] of TL::User) do |acc, ent|
      begin
        case ent
        when Int, .to_i32?
          user = TL.get_user(ent.to_i32)
          acc << user if user
        when /^@[\w\d_]{4,}/i
          if chat = TL.search_public_chat(ent.lstrip('@'))
            user = TL.get_user(chat.id.to_i32)
            acc << user if user
          end
        end
      rescue ex
      end
      acc
    end

    return if users.empty?

    users.map do |usr|
      collect_user_info(usr, args).to_s
    end.join("\n")
  end

  def info_from_reply(msg, args)
    reply_id = msg.reply_to_message_id
    forawrd = args.fetch("forward", true)
    reply_message = TL.get_message(msg.chat_id, reply_id)

    if forawrd && reply_message.forwarded? && (fw_info = reply_message.forward_info)
      origin = fw_info.origin
      if origin.is_a?(TL::MessageForwardOriginUser)
        user_id = origin.sender_user_id
        user = TL.get_user(user_id)
      end
    elsif reply_message.sender_user_id > 0
      user = TL.get_user(reply_message.sender_user_id)
    end

    return unless user

    collect_user_info(user, args)
  end

  def collect_user_info(user, args)
    id_only = args.fetch("id", false)
    show_general = args.fetch("general", true)
    show_bot = args.fetch("bot", false)
    show_misc = args.fetch("misc", false)
    show_spam = args.fetch("spam", false)
    show_all = args.fetch("all", false)

    if show_all
      show_general = true
      show_bot = true
      show_misc = true
      show_spam = true
    end

    if id_only
      return Proton::Utils::MarkdownBuilder.build do
        section do
          mention(Utils.escape_md(user.display_name), user)
          key_value_item("id", code(user.id))
        end
      end
    end

    response = Proton::Utils::MarkdownBuilder.build do
      section do
        mention(Utils.escape_md(user.display_name), user)
        if show_general
          sub_section do
            bold("general")
            key_value_item("id", code(user.id))
            key_value_item("first name", code(user.first_name))
            key_value_item("last name", code(user.last_name))
            key_value_item("username", code(user.username))
            key_value_item("mutual contact", code(user.is_contact))
          end
        end

        if show_bot
          type = user.type
          is_bot = false
          if type.is_a?(TL::UserTypeBot)
            is_bot = true
            can_join_groups = type.can_join_groups
            privacy_mode = type.can_read_all_group_messages
            is_inline = type.is_inline
            inline_query_placeholder = type.inline_query_placeholder
            need_location = type.need_location
          end

          sub_section do
            bold("bot")
            key_value_item("bot", code(is_bot))
            key_value_item("can join groups", code(can_join_groups || false))
            key_value_item("privacy mode", code(privacy_mode || false))
            key_value_item("is inline", code(is_inline || false))
            key_value_item("inline placeholder", code(inline_query_placeholder))
            key_value_item("needs location", code(need_location || false))
          end
        end

        if show_misc
          sub_section do
            bold("misc")
            key_value_item("restricted", code(!user.restriction_reason.empty?))
            key_value_item("restriction reason", code(user.restriction_reason))
            key_value_item("deleted", code(user.type.is_a?(TL::UserTypeDeleted)))
            key_value_item("verified", code(user.is_verified))
            key_value_item("support", code(user.is_support))
            key_value_item("scam", code(user.is_scam))
            key_value_item("language code", code(user.language_code))
          end
        end

        if show_spam && (spamwatch = Utils.spamwatch_client)
          sub_section do
            bold("spamwatch")
            if ban = spamwatch.get_ban(user.id)
              key_value_item("banned", code("true"))
              key_value_item("ban id", code(ban.id))
              key_value_item("reason", ban.reason)
              if date = ban.date
                key_value_item("date", date.to_s("%d/%m/%Y"))
              end
            else
              key_value_item("banned", code("false"))
            end
          end
        end
      end
    end
  end
end
