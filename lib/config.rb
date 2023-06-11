require "strong_yaml"

module TwoCho
  class Config
    include StrongYAML

    file "config.yml"

    schema do
      group :discord do
        integer :application_id
        string :public_key
        string :token
        list :allowed_servers
        list :channels
      end

      group :esrgan do
        string :executable
      end

      group :webserver do
        boolean :use_https
        string :home
        string :domain
        integer :keep_images_for_days
      end
    end
  end
end

TwoCho::Config.create_or_load
