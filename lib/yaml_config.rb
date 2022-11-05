require "yaml"
require "ostruct"

module YAMLConfig
  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    def file(config_location)
      @config = YAML.load_file(config_location)

      @config.each do |key, value|
        define_singleton_method(key) do
          JSON.parse value.to_json, object_class: OpenStruct
        end
      end
    end
  end
end
