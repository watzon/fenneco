class Fennec < Proton::Client
  UWUS = [
    "ÓwÓ", "ÕwÕ", "@w@", "ØwØ", "øwø", "uwu", "◕w◕", "◔w◔", "ʘwʘ", "⓪w⓪", "(owo)",
    "(。O ω O。)", "(。O⁄ ⁄ω⁄ ⁄ O。)", "(O ᵕ O)", "(O꒳O)", "ღ(O꒳Oღ)", "♥(。ᅌ ω ᅌ。)", "(ʘωʘ)", "(⁄ʘ⁄ ⁄ ω⁄ ⁄ ʘ⁄)♡",
    "( ͡o ω ͡o )", "( ͡o ᵕ ͡o )", "( ͡o ꒳ ͡o )", "( o͡ ꒳ o͡ )", "( °꒳° )", "( °ᵕ° )", "( °﹏° )", "( °ω° )",
    "̷(ⓞ̷ ̷꒳̷ ̷ⓞ̷)", "（ ゜ω 。）"
  ]

  @[Help(
    description: "OwO your UwU\n(_Makes you sound like a weeb_)",
    usage: ".owo [text]"
  )]
  @[Command(".owo")]
  def owo_command(ctx)
    if text = (msg = ctx.message.reply_message) ? msg.text : ctx.text
      if text.empty?
        text = UWUS.sample(1)[0]
      else
        text = text.gsub(/[rl]/, "w")
        text = text.gsub(/[RL]/, "W")
        text = text.gsub(/n([aeiou])/, "ny\\1")
        text = text.gsub(/N([aeiouAEIOU])/, "Ny\\1")
        text = text.gsub("!", " " + UWUS.sample(1)[0])
        text = text.gsub("ove", "uv")
        text += " " + UWUS.sample(1)[0]
      end
      edit_message(ctx.message, text)
    end
  end
end
