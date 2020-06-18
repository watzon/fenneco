class Fennec < Proton::Client
  @[Command(/.send(file)?/)]
  def sendfile_command(ctx)
    msg = ctx.message
    url = ctx.text.to_s

    if !url.match(/https?:\/\//)
      return edit_message(msg, "`Invalid url for file sending. Please give a valid url.`")
    end

    delete_message(msg)
    send_message(msg.chat_id!, nil, file: url)
  end
end
