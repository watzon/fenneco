class Fenneco < Proton::Client
  class ArgParser(T)
    alias Value = Array(String) | String | Int64 | Float64 | Bool | Nil

    @defaults : Hash(String, Value)

    def initialize(defaults = {} of String => Value)
      @defaults = defaults.to_h
        .transform_keys(&.to_s)
        .transform_values(&.as(Value))
    end

    def self.parse(text : String, defaults = {} of String => Value)
      parser = new(defaults)
      parser.parse(text)
    end

    def parse(text : String)
      hash = @defaults

      {% for key, value in T %}
        unless hash.has_key?({{ key.id.stringify }})
          {% if value.nilable? %}
            hash[{{ key.id.stringify }}] = nil
          {% elsif value == Bool %}
            hash[{{ key.id.stringify }}] = false
          {% end %}
        end
      {% end %}

      tokens = text.split(' ')
      text = ""

      while token = tokens.shift?
        if match = token.match(/^(\.|!)([\w\d_]+)$/i)
          # Prefixed boolean value
          key = match[2].to_s
          hash[key] = match[1] == "."
        elsif match = token.match(/^([\w\d_]+):(t(rue)?|f(false))$/i)
          # Key/value boolean
          key = match[1].to_s
          hash[key] = match[2].starts_with?('t')
        elsif match = token.match(/^([\w\d_]+):(nil|null)$/i)
          # Nil value
          key = match[1].to_s
          hash[key] = nil
        elsif match = token.match(/^([\w\d_]+):((?:0[xbo])?[\d_.]+(?:e\-\d+)?)$/i)
          # Numeric value
          key = match[1].to_s
          value = match[2]
          hash[key] = value.includes?('.') || value.includes?("e-") ? value.to_f64 : value.to_i64
          elsif match = token.match(/^([\w\d_]+):(\"|\')(\S+)?/)
          # Quoted string value
          key = match[1].to_s
          quote = match[2][0]
          token = match[3]? || ""
          string_parts = [] of String
          loop do
            if token.ends_with?(quote) && !token.ends_with?("\\#{quote}")
              string_parts << token[..-2]
              break
            else
              if tokens.empty?
                raise "Parse Error: Failed to find matching quote."
              end
              string_parts << token
              token = tokens.shift
            end
          end
          hash[key] = string_parts.join(' ')
        elsif match = token.match(/^([\w\d_]+):([\S]+)$/i)
          # String value
          key = match[1].to_s
          hash[key] = match[2]
        else
          tokens.unshift(token)
          text = tokens.join(' ')
          break
        end
      end

      {T.from(hash), text}
    end
  end
end
