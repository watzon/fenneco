class Fenneco < Proton::Client
  @[Help(
    description: "Ｅｍｐｈａｓｉｚｅ ｔｅｘｔ ｉｎ ａ ｆｕｎ ｗａｙ",
    usage: ".vapor <text>"
  )]
  @[Command(".vapor")]
  def vaporwave_command(ctx)
    if text = (msg = ctx.message.reply_message) ? msg.text : ctx.text
      reply = String.build do |str|
        text.chars.each do |chr|
          if (0x21..0x7F).includes?(chr.ord)
            str << (chr.ord + 0xFEE0).chr
          elsif chr.ord == 0x20
            str << 0x3000.chr
          else
            str << chr
          end
        end
      end

      edit_message(ctx.message, reply)
    end
  end
end
