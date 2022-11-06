require_relative "yaml_config"

module TwoCho
  class Config
    include YAMLConfig

    file "config.yml"

    schema do
      group :discord do
        integer :application_id
        string :public_key
        string :token
        list :allowed_servers
      end

      group :esrgan do
        string :home
      end

      group :webserver do
        string :home
        string :domain
      end
    end
  end
end

TwoCho::Config.load
