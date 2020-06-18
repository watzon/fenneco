require "http/client"

class Fenneco < Proton::Client
  @[Help(
    description: "Follow the given url(s) to their destination",
    usage: ".f(ollow) <...urls>"
  )]
  @[Command([".f", ".follow"])]
  def follow_command(ctx)
    msg = ctx.message.reply_message || ctx.message
    urls = msg.text_entities
      .select { |k, _| k.type.is_a?(TL::TextEntityTypeUrl) }
      .map { |_, v| v }

    edit_message(ctx.message, "`Following urls...`")

    urls = urls.uniq.map do |url|
      resolved = resolve_url(url)
      {url, resolved}
    end

    response = Proton::Utils::MarkdownBuilder.build do
      section do
        bold("Follow")
        urls.each do |(original, resolved)|
          key_value_item("original", original)
          key_value_item("resolved", resolved)
          text("\n")
        end
      end
    end

    edit_message(ctx.message, response.to_s)
  end

  private def resolve_url(url)
    resolved = nil
    loop do
      url = "http://#{url.lstrip("//")}" unless url.starts_with?("http")
      response = HTTP::Client.get(url)
      if redirect = response.headers.get?("Location")
        url = redirect.is_a?(Array) ? redirect[0] : redirect
      else
        resolved = url
        break
      end
    end
    resolved.to_s
  end
end
