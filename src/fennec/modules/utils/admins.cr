class Fennec < Proton::Client
  @[Help(
    description: "List the admins for the current chat.",
    args: {
      mention: "mention the admins. sends a new message rather than editing."
    },
    usage: ".admins [args]"
  )]
  @[Command(".admins", edit: true)]
  def admins_command(ctx)
    args, _ = Utils.parse_args(ctx.text)
    args["mention"] ||= false

    admins = get_chat_administrators(ctx.message.chat_id)

    response = Proton::Utils::MarkdownBuilder.build do |md|
      section do
        bold("Admins")
        admins.each do |ad|
          mention(Utils.escape_md(ad.display_name), ad)
        end
      end
    end

    if args["mention"]
      delete_messages(ctx.message.chat_id, [ctx.message])
      send_message(ctx.message.chat_id, response.to_s, reply_to_message: ctx.message.reply_to_message_id)
    else
      edit_message(ctx.message, response.to_s)
    end
  end
end
