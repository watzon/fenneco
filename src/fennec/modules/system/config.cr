class Fennec < Proton::Client
  alias ChatConfigNt = NamedTuple(gbans: Bool?, fbans: Bool?, fban_command: String?, gban_command: String?, welcomes: Bool?, welcome_message: String?, welcome_delay: String?)

  @[Help(
    description: "Set confuguration settings for the current chat and globally.",
    usage: ".config [setting [new value]]"
  )]
  @[Command(".config")]
  def config_command(ctx)
    msg = ctx.message
    chat_id = msg.chat_id!
    args, text = ArgParser(ChatConfigNt).parse(ctx.text)

    args_empty = args.to_a.all? { |k, v| v.nil? }

    if args_empty && text.strip.empty?
    settings = Repo.get_by!(Models::ChatSettings, chat_id: chat_id)

    response = Utils::MarkdownBuilder.build do
      section do
        bold("Config (#{chat_id})")
        {% for opt in ChatConfigNt %}
          key_value_item(bold({{ opt.id.stringify }}), code(settings.{{ opt.id }}))
        {% end %}
      end
    end
    elsif !text.strip.empty?
      key = text.strip
      value = Utils.get_chat_setting(chat_id, key)
      response = Utils::MarkdownBuilder.build do
        section do
          bold("Config (#{chat_id})")
          key_value_item(bold(key), code(value))
        end
      end
    else
      # Set the values
      args.each do |k, v|
        next if v.nil?
        Utils.set_chat_setting(chat_id, k, v)
      end

      response = Utils::MarkdownBuilder.build do
        section do
          bold("Set Config (#{chat_id})")
          args.each do |k, v|
            next if v.nil?
            key_value_item(bold(k), code(v))
          end
        end
      end
    end

    edit_message(msg, response.to_s)
  rescue ex
    edit_message(ctx.message, "`#{ex.message}`")
  end
end
