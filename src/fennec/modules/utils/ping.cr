class Fennec < Proton::Client
  @[Command(".ping", edit: true)]
  def ping_command(ctx)
    elapsed = Time.measure do
      edit_message(ctx.message, "`Pong!`")
    end
    edit_message(ctx.message, "`Pong! #{elapsed.milliseconds}ms`")
  end
end
