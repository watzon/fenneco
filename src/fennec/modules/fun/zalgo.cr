class Fennec < Proton::Client
  ZALG_LIST = [
    ["̖", " ̗", " ̘", " ̙", " ̜", " ̝", " ̞", " ̟", " ̠", " ̤", " ̥", " ̦", " ̩", " ̪", " ̫", " ̬", " ̭", " ̮", " ̯", " ̰", " ̱", " ̲", " ̳", " ̹", " ̺", " ̻", " ̼", " ͅ", " ͇", " ͈", " ͉", " ͍", " ͎", " ͓", " ͔", " ͕", " ͖", " ͙", " ͚", " "],
    [" ̍", " ̎", " ̄", " ̅", " ̿", " ̑", " ̆", " ̐", " ͒", " ͗", " ͑", " ̇", " ̈", " ̊", " ͂", " ̓", " ̈́", " ͊", " ͋", " ͌", " ̃", " ̂", " ̌", " ͐", " ́", " ̋", " ̏", " ̽", " ̉", " ͣ", " ͤ", " ͥ", " ͦ", " ͧ", " ͨ", " ͩ", " ͪ", " ͫ", " ͬ", " ͭ", " ͮ", " ͯ", " ̾", " ͛", " ͆", " ̚"],
    [" ̕", " ̛", " ̀", " ́", " ͘", " ̡", " ̢", " ̧", " ̨", " ̴", " ̵", " ̶", " ͜", " ͝", " ͞", " ͟", " ͠", " ͢", " ̸", " ̷", " ͡"],
  ]

  @[Help(
    description: "Z͈̓a͖̹l̲̼g̵̠ä̵́f̵̄í̻e̸̞s̝͝ t̵͡h̶̫e͉͜ g͒ͧi̵͟v͈́e̷̙n̡͝ t̸ͧę͘x̫ͮt͎ͨ",
    usage: ".zal(go) <text>"
  )]
  @[Command([".zal", ".zalgo"])]
  def zalgo_command(ctx)
    if text = (msg = ctx.message.reply_to_message) ? msg.text : ctx.text
      reply = String.build do |str|
        text.chars.each do |chr|
          if chr.ascii_letter?
            str << chr
            (0..3).each do |i|
              randint = rand(0..2)
              str << ZALG_LIST[randint].sample(1)[0].strip
            end
          else
            str << chr
          end
        end
      end

      edit_message(ctx.message, reply)
    end
  end
end
