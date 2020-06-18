class Fenneco < Proton::Client
  @[Help(
    description: "Ping the server and see how long it takes",
    usage: ".ping"
  )]
  @[Command(".ping", edit: true)]
  def ping_command(ctx)
    elapsed = Time.measure do
      edit_message(ctx.message, "`Pong!`")
    end
    edit_message(ctx.message, "`Pong! #{elapsed.milliseconds}ms`")
  end
end
