require "json"
require "http/client"

require "string_scanner"
require "spamwatch"
require "google"

class Fenneco < Proton::Client
  module Utils
    extend self
    include Proton::Utils

    COMMAND_ARGS_RE = /\s*(((!|\.)[\w\d_\-]+)|(([\w\d_\-]+):[!\w\d_\-]+))\s*/i
    INVITE_LINK_RE = /((?:https?:\/\/)?t\.me\/joinchat\/[\w_\-]+)/
    BOT_TOKEN_RE = /([\d]{6,}:[\w_\-]{35})/

    def log(text, *tags, **options)
      if chat_id = ENV["LOG_CHAT_ID"]?
        if tags.size > 0
          # Add tags as hashtags to the bottom of the message
          # if they exist
          text = String.build do |str|
            str.puts text
            str.puts "----------------------------------------"
            str.puts tags.map { |tag| "##{tag}" }.join(' ')
          end
        end

        Fenneco.client.send_message(chat_id.to_i64, text, **options)
      end
    end

    def spamwatch_client
      if token = ENV["SPAMWATCH_TOKEN"]?
        @@client ||= SpamWatch::Client.new(token)
      end
    end

    def translator
      if auth_file = ENV["GOOGLE_AUTH_FILE"]?
        @@google_auth ||= Google::FileAuth.new(auth_file, scopes: "https://www.googleapis.com/auth/cloud-translation")
        @@translator ||= Google::Translate.new(@@google_auth.not_nil!)
      end
    end

    def parse_args(args)
      scanner = StringScanner.new(args.strip)
      parsed = {} of String => String | Bool
      while match = scanner.scan(COMMAND_ARGS_RE)
        if match.includes?(':')
          key, val = match.split(':', 2)
          parsed[key.strip] = val.strip
        else
          if match.starts_with?('!')
            parsed[match[1..].strip] = false
          else
            parsed[match[1..].strip] = true
          end
        end
      end
      rest = scanner.scan(/([\S\s]+)/)
      {parsed, rest || ""}
    end

    def parse_bool(value)
      case value
      when /t(rue)?|ye(s|ah|)|y(e|u)p/i
        true
      when /f(alse)?|n(ope|ah)?/i
        false
      else raise "Invalid boolean value"
      end
    end

    def paste(text)
      headers = HTTP::Headers{ "X-Api-Key" => ENV["DOGBIN_API_KEY"] } if ENV["DOGBIN_API_KEY"]?
      response = HTTP::Client.post("https://del.dog/documents", headers: headers, body: text)
      if response.status_code < 300
        json = JSON.parse(response.body)
        return "https://del.dog/#{json["key"].as_s}"
      else
        raise "del.dog is experiencing issues right now"
      end
    end

    def persist_chat(chat_id, force_update = false)
      return if chat_id == 0
      chat = Repo.get(Models::Chat, chat_id)
      if chat && (force_update || (updated_at = chat.updated_at) && (Time.utc - 5.days > updated_at))
        # If the chat was last updated more than 5 days ago, update it
        tl_chat = TL.get_chat(chat_id)
        chat.title = tl_chat.title.to_s
        chat.type = Models::Chat::Type.from_tl(tl_chat.type!)
        Repo.update(chat)
      elsif !chat
        # If the chat doesn't exist, add it
        tl_chat = TL.get_chat(chat_id)
        chat = Models::Chat.new
        chat.id = chat_id
        chat.title = tl_chat.title.to_s
        chat.type = Models::Chat::Type.from_tl(tl_chat.type!)
        changeset = Repo.insert(chat)

        settings = Models::ChatSettings.new
        settings.chat = changeset.instance
        Repo.insert(settings)
      end
    end

    def persist_user(user_id, force_update = false)
      return if user_id == 0
      user = Repo.get(Models::User, user_id)
      if user && (force_update || ((updated_at = user.updated_at) && (Time.utc - 5.days > updated_at)))
        # If the user was last updated more than 5 days ago, update it
        tl_user = TL.get_user(user_id)
        user.first_name = tl_user.first_name.to_s
        user.last_name = tl_user.last_name
        user.username = tl_user.username
        user.language_code = tl_user.language_code
        Repo.update(user)
      elsif !user
        # If the user doesn't exist, add it
        tl_user = TL.get_user(user_id)
        user = Models::User.new
        user.id = user_id
        user.first_name = tl_user.first_name.to_s
        user.last_name = tl_user.last_name
        user.username = tl_user.username
        user.language_code = tl_user.language_code
        Repo.insert(user)
      end
    end

    def persist_chat_member(chat_id, user_id)
      return if (user_id == 0 || chat_id == 0)
      query = Crecto::Repo::Query.where("chat_id = ? AND user_id = ?", [chat_id, user_id])
      chat_member = Repo.get_by(Models::ChatMember, query)
      if !chat_member
        chat_member = Models::ChatMember.new
        chat_member.chat_id = chat_id
        chat_member.user_id = user_id
        Repo.insert(chat_member)
      end
    end

    def get_chat_setting(chat, key)
      {% begin %}
        chat_id = chat.is_a?(TL::Chat) ? chat.id : chat.to_i64
        settings = Repo.get_by!(Models::ChatSettings, chat_id: chat_id)
        case key.to_s
        {% for key in %w(gbans fbans gban_command fban_command welcomes welcome_message welcome_delay) %}
        when {{ key.id.stringify }}
          settings.{{ key.id }}
        {% end %}
        else
          raise "Invalid setting #{key}"
        end
      {% end %}
    end

    def set_chat_setting(chat, key, value)
      chat_id = chat.is_a?(TL::Chat) ? chat.id! : chat.to_i64
      settings = Repo.get_by!(Models::ChatSettings, chat_id: chat_id)
      case key.to_s
      when "gbans"
        settings.gbans = !!value
      when "fbans"
        settings.fbans = !!value
      when "gban_command"
        settings.gban_command = value.to_s
      when "fban_command"
        settings.fban_command = value.to_s
      when "welcomes"
        settings.welcomes = !!value
      when "welcome_message"
        settings.welcome_message = value.to_s
      when "welcome_delay"
        settings.welcome_delay = value.to_s
      else
        raise "Setting key '#{key}' does not exist"
      end
      Repo.update(settings)
    end

    def textify_message(message)
      String.build do |str|
        content = message.content!

        case content
        when TL::MessageAnimation
          str.puts "`[gif]`"
        when TL::MessageAudio, TL::MessageVoiceNote
          str.puts "`[audio]`"
        when TL::MessageVideo, TL::MessageVideoNote
          str.puts "`[video]`"
        when TL::MessageDocument
          doc = content.document!
          str.print "`[document"
          if doc.file_name && !doc.file_name!.empty?
            str.print ": #{doc.file_name!}]"
          end
          str.puts
        when TL::MessagePhoto
          str.puts "`[photo]`"
        when TL::MessageSticker
          str.puts "`[sticker]`"
        when TL::MessageContact
          str.puts "`[contact]`"
        end

        if text = message.raw_text
          str.puts text
        else
          str.puts "`[no text/caption]`"
        end
      end
    end

    def user_from_message(msg, forward = true)
      reply_id = msg.reply_to_message_id!
      reply_message = TL.get_message(msg.chat_id!, reply_id)

      if forward && reply_message.forwarded? && (fw_info = reply_message.forward_info)
        origin = fw_info.origin
        if origin.is_a?(TL::MessageForwardOriginUser)
          user_id = origin.sender_user_id!
          user = TL.get_user(user_id)
        end
      elsif reply_message.sender_user_id! > 0
        user = TL.get_user(reply_message.sender_user_id!)
      end

      user
    end

    def users_from_entities(msg, ents)
      text_entities = msg.text_entities.keys.map(&.type).select(&.is_a?(TL::TextEntityTypeMentionName))
      uids = text_entities.map(&.as(TL::TextEntityTypeMentionName).user_id!)

      # Map over the given entities. They could be ids, usernames, or garbage text.
      # We need to resolve them if possible and add them to an array.
      (ents + uids).reduce([] of TL::User) do |acc, ent|
        begin
          case ent
          when Int, .to_i32?
            user = TL.get_user(ent.to_i32)
            acc << user if user
          when /^@[\w\d_]{4,}/i
            if chat = TL.search_public_chat(ent.lstrip('@'))
              user = TL.get_user(chat.id!.to_i32)
              acc << user if user
            end
          end
        rescue ex
        end
        acc
      end
    end
  end
end
