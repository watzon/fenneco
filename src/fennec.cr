require "totem"
require "proton"

require "./fennec/config/*"
require "./fennec/utils"
require "./fennec/modules/**"

class Fennec < Proton::Client
  CONFIG_DEFAULTS = {
    "use_test_dc" => false,
    "database_directory" => Path.home.join(".config/fennec/tdlib").to_s,
    "files_directory" => "",
    "use_file_database" => true,
    "use_chat_info_database" => true,
    "use_message_database" => true,
    "use_secret_chats" => false,
    "system_language_code" => "en",
    "device_model" => "Desktop",
    "system_version" => "Linux",
    "application_version" => Fennec::VERSION,
    "enable_storage_optimizer" => true,
    "ignore_file_names" => false,
    "verbosity_level" => 1,
    "request_timeout" => 30
  }

  class_getter config : Totem::Config { Totem.new("config") }

  getter me : TL::User { TL.get_me }

  def initialize(auth_flow : Proton::AuthFlow)
    Fennec.config.config_paths << "."
    Fennec.config.config_paths << Path.home.join(".Fennec").to_s
    Fennec.config.config_paths << Path.home.join(".config/Fennec/").to_s
    Fennec.config.set_defaults(CONFIG_DEFAULTS)
    Fennec.config.automatic_env(prefix: "Fennec")

    begin
      Fennec.config.load!
    rescue ex
      Log.fatal(exception: ex) { "Failed to load config file" }
      exit(1)
    end

    pp! Fennec.config.get("database_directory").as_s

    super(
      auth_flow: auth_flow,
      api_id: Fennec.config.get("api_id").as_i,
      api_hash: Fennec.config.get("api_hash").as_s,
      verbosity_level: Fennec.config.get("verbosity_level").as_i,
      timeout: Fennec.config.get("request_timeout").as_i.seconds,
      use_test_dc: Fennec.config.get("use_test_dc").as_bool,
      database_directory: Fennec.config.get("database_directory").as_s,
      files_directory: Fennec.config.get("files_directory").as_s,
      use_file_database: Fennec.config.get("use_file_database").as_bool,
      use_chat_info_database: Fennec.config.get("use_chat_info_database").as_bool,
      use_message_database: Fennec.config.get("use_message_database").as_bool,
      use_secret_chats: Fennec.config.get("use_secret_chats").as_bool,
      system_language_code: Fennec.config.get("system_language_code").as_s,
      device_model: Fennec.config.get("device_model").as_s,
      system_version: Fennec.config.get("system_version").as_s,
      application_version: Fennec.config.get("application_version").as_s,
      enable_storage_optimizer: Fennec.config.get("enable_storage_optimizer").as_bool,
      ignore_file_names: Fennec.config.get("ignore_file_names").as_bool
    )
  end

  @[Command(".status", edited: true )]
  def status_command(ctx)
    edit_message(ctx.message, "`Firing on all cylinders!`")
  end

  # @[OnMessage(edited: true)]
  # def on_new_message(ctx)
  #   if (text = ctx.raw_text) && !text.empty?
  #     puts
  #     puts "---------------------------------"
  #     puts ctx.edited ? "Edited:" : ""
  #     puts text
  #     puts
  #     puts "---------------------------------"
  #     puts
  #   end
  # end
end

client = Fennec.new(Proton::TerminalAuthFlow.new(encryption_key: ""))
client.start
