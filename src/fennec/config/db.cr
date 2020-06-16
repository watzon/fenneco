require "pg"
require "crecto"

class Fennec < Proton::Client
  module Repo
    extend Crecto::Repo

    config do |conf|
        conf.adapter = Crecto::Adapters::Postgres
        conf.max_pool_size = ENV.fetch("DB_MAX_POOL_SIZE", "20").to_i
        conf.initial_pool_size = ENV.fetch("DB_INITIAL_POOL_SIZE", "5").to_i

        if database_uri = ENV["DB_URI"]?
          conf.uri = database_uri
        else
          conf.hostname = ENV["DB_HOST"]
          conf.database = ENV["DB_NAME"]
          conf.username = ENV["DB_USER"]? || ""
          conf.password = ENV["DB_PASS"]? || ""
        end
    end
  end
end
