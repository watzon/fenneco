class Fenneco < Proton::Client
  @[Command(".transcript")]
  def transcript_command(ctx)
    msg = ctx.message
    args, text = ArgParser({start: Bool, stop: Bool, save: Bool}).parse(ctx.text)

    unless args[:start] || args[:stop] || args[:save]
      return edit_message(msg, "`Please use either .start, .stop, or .save`")
    end

    if args[:start]
      # Start recording a chat transcript

    elsif args[:stop]
      # Stop recording a chat transcript

    elsif args[:save]
      # Save the transcript, deleting the records from the
      # database and logging the result as a paste bin link

    end
  end
end
