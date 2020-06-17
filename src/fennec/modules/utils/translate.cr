class Fennec < Proton::Client
  @[Help(
    description: "Translate text using the Google Translate API",
    arguments: {
      to: "language to translate to; defaults to 'en'",
      from: "language to translate from; no value results in language detection"
    },
    usage: ".tr(anslate) [args] <text>"
  )]
  @[Command(/.tr(anslate)?/)]
  def translate_command(ctx)
    if translator = Utils.translator
      args, message_text = ArgParser({to: String, from: String?, silent: Bool}).parse(ctx.text, {to: "en"})
      if text = (msg = ctx.message.reply_message) ? msg.text : message_text

        if args[:silent]
          delete_message(ctx.message)
        else
          edit_message(ctx.message, "`Translating text...`")
        end

        result = translator.translate(text, to: args[:to], from: args[:from])

        if result.size < 1
          if args[:silent]
            response = Utils::MarkdownBuilder.build do
              section(indent: 0) do
                bold("Message translation failed")
                bold("Message text:")
                code(text)
              end
            end

            Utils.log(response.to_s, "translation", "error")
          else
            return edit_message(ctx.message, "`Failed to translate message.`")
          end
        end

        language = result[0].detected_source_language
        translation_result = result[0].translated_text

        if args[:silent]
          from_user = msg.from_user if msg
          response = Utils::MarkdownBuilder.build do
            section(indent: 0) do
              bold("Translation result")
              key_value_item(bold("User"), mention(from_user.display_name, from_user)) if from_user
              key_value_item(bold("Message"), text(msg.link.to_s)) if msg
              text("\n")

              sub_section(indent: 0) do
                bold("Original (#{language}):")
                code(text)
              end

              text("\n")
              sub_section(indent: 0) do
                bold("Translation (#{args[:to]}):")
                code(translation_result)
              end
            end
          end

          Utils.log(response.to_s, "translation")
        else
          response = Utils::MarkdownBuilder.build do
            section(indent: 0) do
              bold("Translation (#{language} to #{args[:to]}):")
              code(translation_result)
            end
          end

          edit_message(ctx.message, response.to_s)
        end
      end
    end
  end
end
