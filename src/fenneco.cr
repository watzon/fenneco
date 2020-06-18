require "dotenv"
require "proton"
require "humanize_time"

Dotenv.load?

require "./fenneco/version"
require "./fenneco/config/*"
require "./fenneco/utils"
require "./fenneco/help"
require "./fenneco/models/*"
require "./fenneco/arg_parser"
require "./fenneco/modules/**"

class Fenneco < Proton::Client
  getter me : TL::User { TL.get_me }

  getter module_help : ModuleHelp

  class_getter! client : Fenneco

  def initialize(auth_flow : Proton::AuthFlow)
    super(
      auth_flow: auth_flow,
      api_id: ENV.fetch("API_ID").to_i,
      api_hash: ENV.fetch("API_HASH"),
      timeout: ENV.fetch("TD_REQUEST_TIMEOUT", "3600").to_i.seconds,
      use_test_dc: !!ENV.fetch("TD_USE_TEST_DC", "false").match(/1|t(rue)?/i),
      database_directory: ENV.fetch("TD_DATABASE_DIRECTORY", Path.home.join(".config/fenneco/tdlib").to_s),
      files_directory: ENV.fetch("TD_FILES_DIRECTORY", ""),
      use_file_database: !!ENV.fetch("TD_USE_FILE_DATABASE", "true").match(/1|t(rue)?/i),
      use_chat_info_database: !!ENV.fetch("TD_USE_CHAT_INFO_DATABASE", "true").match(/1|t(rue)?/i),
      use_message_database: !!ENV.fetch("TD_USE_MESSAGE_DATABASE", "true").match(/1|t(rue)?/i),
      use_secret_chats: !!ENV.fetch("TD_USE_SECRET_CHATS", "true").match(/1|t(rue)?/i),
      system_language_code: ENV.fetch("TD_SYSTEM_LANGUAGE_CODE", "en"),
      device_model: ENV.fetch("TD_DEVICE_MODEL", "Desktop"),
      system_version: ENV.fetch("TD_SYSTEM_VERSION", "Linux"),
      application_version: ENV.fetch("TD_APPLICATION_VERSION", Fenneco::VERSION),
      enable_storage_optimizer: !!ENV.fetch("TD_ENABLE_STORAGE_OPTIMIZER", "true").match(/1|t(rue)?/i),
      ignore_file_names: !!ENV.fetch("TD_IGNORE_FILE_NAMES", "false").match(/1|t(rue)?/i)
    )

    @module_help = ModuleHelp.from_annotations
    @@client = self
  end
end

client = Fenneco.new(Proton::TerminalAuthFlow.new(encryption_key: ""))
client.set_tdlib_verbosity(ENV.fetch("VERBOSITY_LEVEL", "1").to_i)
client.start do |update|
  spawn client.persistence_listener(update)
end
