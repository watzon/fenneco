class Fennec < Proton::Client
  @[Help(
    description: "Display general or module specific help",
    usage: ".help [module name]"
  )]
  @[Command(".help")]
  def help_command(ctx)
    msg = ctx.message
    command = ctx.text.downcase.strip
    help = self.module_help

    if command.empty?
      response = help.render_help
      edit_message(msg, response.to_s)
    else
      if response = help.render_help_for(command)
        edit_message(msg, response.to_s)
      else
        edit_message(msg, "`No help for command #{command}. Did you spell it wrong?`")
      end
    end
  end
end
