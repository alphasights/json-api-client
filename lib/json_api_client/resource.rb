module JsonApiClient
  module Resource
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def api_client
        @api_client ||= Consumer.new(@resource_config_prefix)
      end

      def mapper
        @mapper ||= Mapper.new(resource, @resource_methods)
      end

      def resource(resource = nil)
        @resource = String(resource) unless resource.nil?
        @resource
      end

      def resource_config_prefix(resource_config_prefix)
        @resource_config_prefix = String(resource_config_prefix)
      end

      def resource_methods(&block)
        @resource_methods = block
      end
    end
  end
end
