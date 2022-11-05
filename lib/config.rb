require_relative "yaml_config"

module TwoCho
  class Config
    include YAMLConfig

    file "config.yml"
  end
end
