module JsonApiClient
  class Error < StandardError; end
  class MissingDependency < Error; end

  class ClientError < Error
    def initialize(ex)
      @wrapped_exception = nil

      if ex.respond_to?(:backtrace)
        super(ex.message)
        @wrapped_exception = ex
      elsif ex.respond_to?(:each_key)
        super("the server responded with status #{ex[:status]}")
      else
        super(ex.to_s)
      end
    end

    def backtrace
      if @wrapped_exception
        @wrapped_exception.backtrace
      else
        super
      end
    end

    def inspect
      %(#<#{self.class}>)
    end
  end

  class ConnectionFailed < ClientError;   end
  class ResourceNotFound < ClientError;   end
  class ParsingError     < ClientError;   end

  class TimeoutError < ClientError
    def initialize(ex = nil)
      super(ex || "timeout")
    end
  end

  class SSLError < ClientError
  end

  [:MissingDependency, :ClientError, :ConnectionFailed, :ResourceNotFound,
   :ParsingError, :TimeoutError, :SSLError].each do |const|
    Error.const_set(const, JsonApiClient.const_get(const))
  end
end
