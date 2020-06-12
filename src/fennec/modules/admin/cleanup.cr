class Fennec < Proton::Client
  @[Help(
    description: "Clean the chat of deleted members",
    args: {
      count: "count deleted accounts rather than removing them (`true` by default if not admin)",
      silent: "don't send updates to the chat"
    },
    usage: ".clean(up) [args]"
  )]
  @[Command(/\.clean(up)?/)]
  def cleanup_command(ctx)
    msg = ctx.message
    chat = TL.get_chat(msg.chat_id)
    chat_member = TL.get_chat_member(chat.id, me.id)
    args, _ = Utils.parse_args(ctx.text)

    count_only = args.fetch("count", false)
    silent = args.fetch("silent", false)

    unless chat_member.creator? || chat_member.administrator?
      count_only = true
    end

    if silent
      spawn delete_messages(chat, [msg])
    else
      edit_message(msg, "`Cleaning up. This could take a minute.`")
    end

    response = cleanup_chat(ctx, chat, count: count_only, silent: silent)

    unless silent
      edit_message(msg, response.to_s)
    end
  end

  private def cleanup_chat(ctx, chat, count, silent)
    msg = ctx.message
    deleted_users = 0
    user_counter = 0

    supergroup_id = chat.type.as(TL::ChatTypeSupergroup).supergroup_id
    supergroup = TL.get_supergroup(supergroup_id)

    banned_status = TL::ChatMemberStatusBanned.new(0)
    deleted_accounts_label = Utils::MarkdownBuilder::Bold.new("#{count ? "Counted" : "Removed"} Deleted Accounts")
    participant_count = supergroup.member_count

    loop do
      response = TL.get_supergroup_members(supergroup_id, TL::SupergroupMembersFilterRecent.new, user_counter, 100)
      members = response.members
      break if members.empty?
      user_counter += members.size

      members.each do |member|
        spawn do
          if user = TL.get_user(member.not_nil!.user_id)
            if user.deleted?
              TL.set_chat_member_status(msg.not_nil!.chat_id, user.not_nil!.id, banned_status.not_nil!) unless count
              deleted_users += 1
            end
          end
        end
      end

      if !silent
        progress = Proton::Utils::MarkdownBuilder.build do
          section do
            bold("Cleanup")
            key_value_item(bold("Progress"), "#{user_counter}/#{participant_count}")
            key_value_item(deleted_accounts_label, deleted_users)
          end
        end
        spawn edit_message(msg, progress.to_s)
      end

      sleep 1
    end

    Proton::Utils::MarkdownBuilder.build do
      section do
        bold("Cleanup")
        key_value_item(deleted_accounts_label, deleted_users)
      end
    end
  end
end
