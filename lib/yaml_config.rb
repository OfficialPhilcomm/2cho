require "yaml"
require "ostruct"

module YAMLConfig
  class ConfigSchema
    attr_reader :elements

    def initialize
      @elements = []
    end

    def group(name, &block)
      group = ConfigGroup.new(name)
      @elements << group
      group.instance_eval(&block)
    end

    def string(name)
      @elements << ConfigString.new(name)
    end

    def integer(name)
      @elements << ConfigInteger.new(name)
    end

    def list(name)
      @elements << ConfigList.new(name)
    end

    class ConfigGroup
      attr_reader :name, :elements

      def initialize(name)
        @name = name
        @elements = []
      end

      def group(name, &block)
        group = ConfigGroup.new(name)
        @elements << group
        group.instance_eval(&block)
      end

      def string(name)
        @elements << ConfigString.new(name)
      end

      def integer(name)
        @elements << ConfigInteger.new(name)
      end

      def list(name)
        @elements << ConfigList.new(name)
      end
    end

    class ConfigString
      attr_reader :name

      def initialize(name)
        @name = name
      end
    end

    class ConfigInteger
      attr_reader :name

      def initialize(name)
        @name = name
      end
    end

    class ConfigList
      attr_reader :name

      def initialize(name)
        @name = name
      end
    end
  end

  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    def file(config_location)
      @config_location = config_location
    end

    def schema(&block)
      @schema = ConfigSchema.new
      @schema.instance_eval(&block)
    end

    def load
      @config = YAML.load_file(@config_location)

      if @schema
        @schema.elements.each do |schema_entry|
          obj = build_schema_entry schema_entry, @config, []

          define_singleton_method(schema_entry.name) do
            obj
          end
        end
      else
        @config.each do |key, value|
          define_singleton_method(key) do
            JSON.parse value, object_class: OpenStruct
          end
        end
      end
    end

    private

    def build_schema_entry(schema_entry, config, path)
      if schema_entry.is_a? YAMLConfig::ConfigSchema::ConfigGroup
        obj = OpenStruct.new
        schema_entry.elements.each do |se|
          obj[se.name] = build_schema_entry(se, config, path + [schema_entry.name])
        end
        obj
      else
        path << schema_entry.name
        config.dig(*path.map(&:to_s))
      end
    end
  end
end
