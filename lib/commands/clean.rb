require "tty-option"
require "fileutils"
require_relative "../config"

module TwoCho
  module Commands
    class Clean
      include TTY::Option

      program "2cho"
      no_command

      def run
        folders = Dir.entries(TwoCho::Config.webserver.home).select do |entry|
          File.directory?(File.join(TwoCho::Config.webserver.home, entry)) &&
            entry.match(/\d{8}/) &&
            (Date.today - Date.parse(entry)) > TwoCho::Config.webserver.keep_images_for_days
        end

        folders.each do |folder|
          FileUtils.rm_rf File.join(TwoCho::Config.webserver.home, folder)
        end
      end
    end
  end
end
