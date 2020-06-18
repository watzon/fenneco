class Fennec < Proton::Client
  @[OnMessage]
  def pattern_logger_listener(ctx)
    log_chat_id = ENV["LOG_CHAT_ID"]?.try &.to_i64
    return if ctx.message.chat_id! == log_chat_id

    if (text = ctx.text)
      if match = text.match(Utils::BOT_TOKEN_RE)
        # We found a bot token! Lol
        log_pattern("Bot Token", Utils.escape_md(match[1]), ctx.message)
      end

      if match = text.match(Utils::INVITE_LINK_RE)
        # Some shitty invite link
        log_pattern("Invite Link", Utils.escape_md(match[1]), ctx.message)
      end
    end
  end

  def log_pattern(key, value, message)
    from_user = message.from_user
    response = Utils::MarkdownBuilder.build do
      section do
        bold("Pattern Matched")
        key_value_item(bold("User"), from_user.inline_mention) if from_user
        key_value_item(bold("Message"), message.link.to_s)
        key_value_item(bold(key), value)
      end
    end

    Utils.log(response.to_s, "patternmatch")
  end
end
