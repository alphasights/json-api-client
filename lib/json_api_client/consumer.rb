require "faraday"
require "faraday_middleware"
require "oj"

module JsonApiClient
  class Consumer
    def initialize(name)
      @name = name
    end

    %i(get put post).each do |verb|
      define_method(verb) do |url, params = {}|
        begin
          connection.public_send(verb, url, params) do |request|
            request.headers["Content-Type"] = "application/vnd.api+json"
            request.body = Oj.dump(params) if params_as_json_body?(verb)
          end
        rescue Faraday::Error => e
          raise "JsonApiClient::#{e.class.name.demodulize}".constantize.new(e)
        end
      end
    end

    def connection
      @connection ||= Faraday.new(url: config(:base_url)).tap do |connection|
        connection.authorization :Token, config(:token)
        connection.use Faraday::Response::RaiseError
        connection.use FaradayMiddleware::ParseJson, content_type: /\bjson$/
      end
    end

    private

    def params_as_json_body?(verb)
      %i(put post).include?(verb)
    end

    def config(key)
      env_var = "#{@name}_#{key}".upcase
      ENV.fetch(env_var)
    rescue KeyError
      raise KeyError.new("Environment variable #{env_var} was requested, but is not set")
    end
  end
end
