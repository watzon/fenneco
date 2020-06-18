class Fenneco < Proton::Client
  @[Help(
    description: "Display information about a user",
    args: {
      id: "display only the name and id",
      general: "display general info (default: `true`)",
      bot: "display bot information",
      misc: "display miscellanious information",
      spam: "use the SpamWatch API to fetch ban information",
      common: "display all groups shared with the user",
      all: "set all of the above to `true`",
      forward: "follow the forwarded message (default: `true`)"
    },
    usage: ".u(ser) [args] [...users]"
  )]
  @[Command([".u", ".user"])]
  def user_info_command(ctx)
    msg = ctx.message

    args, text = ArgParser({
      forward: Bool,
      id: Bool,
      general: Bool,
      bot: Bool,
      misc: Bool,
      common: Bool,
      spam: Bool,
      all: Bool
    }).parse(ctx.text, {general: true, forward: true})

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
    users = Utils.users_from_entities(msg, ents)
    return if users.empty?
    users.map do |usr|
      collect_user_info(usr, args).to_s
    end.join("\n")
  end

  def info_from_reply(msg, args)
    forward = args[:forward]
    if user = Utils.user_from_message(msg, forward)
      collect_user_info(user, args)
    end
  end

  def collect_user_info(user, args)
    id_only = args[:id]
    show_general = args[:general]
    show_bot = args[:bot]
    show_misc = args[:misc]
    show_common = args[:common]
    show_spam = args[:spam]
    show_all = args[:all]

    if show_all
      show_general = true
      show_bot = true
      show_misc = true
      show_common = true
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
          gban_status = Repo.get_by(Models::Gban, user_id: user.id!)

          sub_section do
            bold("general")
            key_value_item("id", code(user.id))
            key_value_item("first name", code(user.first_name))
            key_value_item("last name", code(user.last_name))
            key_value_item("username", code(user.username))
            key_value_item("gbanned", code(!!gban_status))
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
            key_value_item("restricted", code(!user.restriction_reason!.empty?))
            key_value_item("restriction reason", code(user.restriction_reason))
            key_value_item("deleted", code(user.type.is_a?(TL::UserTypeDeleted)))
            key_value_item("verified", code(user.is_verified))
            key_value_item("support", code(user.is_support))
            key_value_item("scam", code(user.is_scam))
            key_value_item("language code", code(user.language_code))
          end
        end

        if show_common
          common_groups = TL.get_groups_in_common(user.id!, 0, 100)
          sub_section do
            bold("common groups")
            if (chat_ids = common_groups.chat_ids!) && !chat_ids.empty?
              chat_ids.each do |id|
                if (chat = TL.get_chat(id)) && (sg = chat.supergroup)
                  text(sg.username!.empty? ? "`#{chat.title}`" : "@#{sg.username}")
                end
              end
            else
              text("No common groups")
            end
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
