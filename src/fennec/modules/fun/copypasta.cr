class Fennec < Proton::Client
  CP_EMOJIS = [
    "😂", "👌", "😂", "✌", "💞", "👍", "👌", "💯", "🎶", "👀", "😂", "👓", "👏", "👐", "🍕",
    "💥", "🍴", "💦", "💦", "🍑", "🍆", "😩", "😏", "👉👌", "👀", "👅", "😩", "🚰"
  ]

  @[Command(".cp", edited: true)]
  def copypasta_command(ctx)
    if text = (msg = ctx.message.reply_to_message) ? msg.text : ctx.text
      chars = text.chars
      random = Random.new

      first_emoji = CP_EMOJIS.sample(1)[0]
      b_index = rand(0..(chars.size - 1))

      response = chars.map_with_index do |chr, i|
        if chr.ascii_whitespace?
          CP_EMOJIS.sample(1)[0]
        elsif CP_EMOJIS.includes?(chr.to_s)
          chr.to_s + CP_EMOJIS.sample(1)[0]
        elsif i == b_index
          "🅱️"
        else
          if random.next_bool
            chr.upcase
          else
            chr.downcase
          end
        end
      end

      response = [CP_EMOJIS.sample(1)[0]] + response + [CP_EMOJIS.sample(1)[0]]
      edit_message(ctx.message, response.join)
    end
  end
end
