class Fennec < Proton::Client
  FINGER_ANIMATION_FRAMES = [
    "▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒\nLoading response...",
    "█▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒\nLoading response...",
    "██▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒\nLoading response...",
    "███▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒\nLoading response...",
    "████▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒\nPlease be patient...",
    "███████▒▒▒▒▒▒▒▒▒▒▒▒▒▒\nPlease be patient...",
    "████████▒▒▒▒▒▒▒▒▒▒▒▒▒\nPlease be patient...",
    "██████████▒▒▒▒▒▒▒▒▒▒▒\nPlease be patient...",
    "███████████████▒▒▒▒▒▒\nPlease be patient...",
    "███████████████▒▒▒▒▒▒\nWe're almost there...",
    "████████████████▒▒▒▒▒\nWe're almost there...",
    "█████████████████▒▒▒▒\nWe're almost there...",
    "██████████████████▒▒▒\nWe're almost there...",
    "███████████████████▒▒\nWe're almost there...",
    nil,
    nil,
    nil,
    "████████████████████▒\nWe're almost there...",
    "█████████████████████\nDone!",
    nil,
  ]

  FINGER_RESPONSE_GIF = "src/fennec/images/finger.gif"

  @[Command(".finger")]
  def finger_command(ctx)
    msg = ctx.message

    # Do the animation
    FINGER_ANIMATION_FRAMES.each do |frame|
      if frame
        edit_message(msg, frame)
      end
      sleep(1)
    end

    delete_message(msg)
    send_message(msg.chat_id!, nil, file: FINGER_RESPONSE_GIF, reply_message: msg.reply_message)
  end
end
