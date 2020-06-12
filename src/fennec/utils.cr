require "json"
require "http/client"

require "string_scanner"
require "spamwatch"

class Fennec < Proton::Client
  module Utils
    extend self
    include Proton::Utils

    COMMAND_ARGS_RE = /\s*(((!|\.)[\w\d_\-]+)|(([\w\d_\-]+):[!\w\d_\-]+))\s*/i

    def spamwatch_client
      if token = Fennec.config["spamwatch_token"]?
        token = token.as_s
        @@client ||= SpamWatch::Client.new(token)
      end
    end

    def parse_args(args)
      scanner = StringScanner.new(args.strip)
      parsed = {} of String => String | Bool
      while match = scanner.scan(COMMAND_ARGS_RE)
        if match.includes?(':')
          key, val = match.split(':', 2)
          parsed[key.strip] = val.strip
        else
          if match.starts_with?('!')
            parsed[match[1..].strip] = false
          else
            parsed[match[1..].strip] = true
          end
        end
      end
      rest = scanner.scan(/([\S\s]+)/)
      {parsed, rest || ""}
    end

    def paste(text)
      response = HTTP::Client.post("https://del.dog/documents", body: text)
      if response.status_code < 300
        json = JSON.parse(response.body)
        return "https://del.dog/#{json["key"].as_s}"
      else
        raise "del.dog is experiencing issues right now"
      end
    end
  end
end
