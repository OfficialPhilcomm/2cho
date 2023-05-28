require "tty-option"
require_relative "../settings"
require_relative "../upscale_bot"

module TwoCho
  module Commands
    class Base
      include TTY::Option

      program "2cho"
      no_command

      flag :help do
        short "-h"
        long "--help"
        desc "Print this page"
      end

      option :environment do
        desc "Set the environment"
        short "-e"
        long "--environment environment"

        default :production
        permit [:development, :production]
        convert :symbol
      end

      def run
        if params[:help]
          print help
          exit
        end

        if !params[:environment]
          puts "Environment must either be development or production"
          exit 1
        end

        Settings.set_environment(params[:environment])

        TwoCho::UpscaleBot.new.run
      end
    end
  end
end
