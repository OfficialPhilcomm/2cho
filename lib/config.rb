require "yaml"
require "ostruct"

module TwoCho
  class Config
    def self.init
      config = YAML.load_file("config.yml")

      config.each do |key, value|
        define_singleton_method(key) do
          OpenStruct.new(value)
        end
      end
    end
  end
end
