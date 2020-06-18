require "dotenv"
require "proton"
require "humanize_time"

Dotenv.load?

require "./fennec/version"
require "./fennec/config/*"
require "./fennec/utils"
require "./fennec/help"
require "./fennec/models/*"
require "./fennec/arg_parser"
require "./fennec/modules/**"

class Fennec < Proton::Client
  getter me : TL::User { TL.get_me }

  getter module_help : ModuleHelp

  class_getter! client : Fennec

  def initialize(auth_flow : Proton::AuthFlow)
    super(
      auth_flow: auth_flow,
      api_id: ENV.fetch("API_ID").to_i,
      api_hash: ENV.fetch("API_HASH"),
      timeout: ENV.fetch("REQUEST_TIMEOUT", "3600").to_i.seconds,
      use_test_dc: !!ENV.fetch("USE_TEST_DC", "false").match(/1|t(rue)?/i),
      database_directory: ENV.fetch("DATABASE_DIRECTORY", Path.home.join(".config/fennec/tdlib").to_s),
      files_directory: ENV.fetch("FILES_DIRECTORY", ""),
      use_file_database: !!ENV.fetch("USE_FILE_DATABASE", "true").match(/1|t(rue)?/i),
      use_chat_info_database: !!ENV.fetch("USE_CHAT_INFO_DATABASE", "true").match(/1|t(rue)?/i),
      use_message_database: !!ENV.fetch("USE_MESSAGE_DATABASE", "true").match(/1|t(rue)?/i),
      use_secret_chats: !!ENV.fetch("USE_SECRET_CHATS", "true").match(/1|t(rue)?/i),
      system_language_code: ENV.fetch("SYSTEM_LANGUAGE_CODE", "en"),
      device_model: ENV.fetch("DEVICE_MODEL", "Desktop"),
      system_version: ENV.fetch("SYSTEM_VERSION", "Linux"),
      application_version: ENV.fetch("APPLICATION_VERSION", Fennec::VERSION),
      enable_storage_optimizer: !!ENV.fetch("ENABLE_STORAGE_OPTIMIZER", "true").match(/1|t(rue)?/i),
      ignore_file_names: !!ENV.fetch("IGNORE_FILE_NAMES", "false").match(/1|t(rue)?/i)
    )

    @module_help = ModuleHelp.from_annotations
    @@client = self
  end
end

client = Fennec.new(Proton::TerminalAuthFlow.new(encryption_key: ""))
client.set_tdlib_verbosity(ENV.fetch("VERBOSITY_LEVEL", "1").to_i)
client.start do |update|
  spawn client.persistence_listener(update)
end
