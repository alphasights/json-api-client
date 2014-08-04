require "active_support/inflector"

module JsonApiClient
  class Mapper
    attr_reader :primary_resource, :primary_resource_methods

    def initialize(primary_resource, primary_resource_methods = nil)
      @primary_resource = primary_resource
      @primary_resource_methods = primary_resource_methods
    end

    def call(data, resource_type = primary_resource)
      data.fetch(resource_type).map do |resource|
        except_links = resource.reject { |k, _| k == "links" }
        properties = except_links.keys.map(&:to_sym)
        values = except_links.values

        apply_linked_resources(resource, data, properties, values)

        class_name = resource_type.camelize.singularize
        klass = generate_class(class_name, properties, &primary_resource_methods)
        klass.new(*values)
      end
    end

    private

    def generate_class(class_name, properties, &primary_resource_methods)
      @classes ||= {}
      @classes[class_name] ||= Struct.new(class_name, *properties, &primary_resource_methods)
    end

    def apply_linked_resources(resource, data, properties, values)
      return {} unless data["linked"]

      link_type_map = build_link_type_map(data)

      resource["links"].map do |association, id|
        type = link_type_map[association]

        if linked_resource = get_linked_resources(data, type, id)
          values << linked_resource
          properties << association.to_sym
        end
      end
    end

    def get_linked_resources(data, type, id_or_ids)
      map = build_linked_resources_map(data)

      multiple = id_or_ids.is_a?(Array)

      if multiple
        id_or_ids.map{ |id| send(__method__, data, type, id) }
      else
        return unless resource = map[type] && map[type][id_or_ids]

        value = call({ type => [resource].flatten}, type)

        multiple ? value : value.first
      end
    end

    # Builds a map to enable getting references by type and id
    #
    # eg.
    # {
    #   "users" => {
    #     "1" => { "id" => "1", "name" => "John" },
    #     "5" => { "id" => "5", "name" => "Walter" },
    #   }
    # }
    def build_linked_resources_map(data)
      data["linked"].each_with_object({}) do |(type, resources), obj|
        obj[type] ||= {}
        resources.each do |linked_resource|
          obj[type][linked_resource["id"]] = linked_resource
        end
      end
    end

    # Builds a map to translate references to types
    #
    # eg.
    # { "author" => "users", "comments" => "comments" }
    def build_link_type_map(data)
      data["links"].each_with_object({}) do |(key, value), obj|
        association = key.split(".").last
        obj[association] = value["type"].pluralize
      end
    end
  end
end
