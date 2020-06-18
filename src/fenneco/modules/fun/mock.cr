class Fenneco < Proton::Client
  @[Help(
    description: "be SArCAStiC aF, or Not",
    usage: ".mock <text>"
  )]
  @[Command(".mock", edited: true)]
  def mock_command(ctx)
    if text = (msg = ctx.message.reply_message) ? msg.text : ctx.text
      random = Random.new
      chars = text.chars.map do |chr|
        if chr.ascii_letter? && random.next_bool
          chr.ascii_lowercase? ? chr.upcase : chr.downcase
        else
          chr
        end
      end
      edit_message(ctx.message, chars.join)
    end
  end
end
