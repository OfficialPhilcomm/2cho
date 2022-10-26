require "pry"
require "time"
require "open3"
require "dotenv"
require "httparty"
require "tempfile"
require "discordrb"

module TwoCho
  class TwoCho::UpscaleBot
    attr_reader :bot

    def initialize
      build_bot
    end

    def run
      bot.run
    end

    private

    def build_bot
      @bot = Discordrb::Bot.new(token: ENV["TOKEN"])

      bot.mention in: "#screenshots" do |event|
        unless event.message.attachments.any?
          event.respond "I can only upscale an image if you attach one to the message you ping me in"
          next
        end

        unless event.message.attachments.one?
          event.respond "Please send only one image per message for now (this is being worked on)"
          next
        end

        attachment = event.message.attachments.first

        unless attachment.image?
          event.respond "Please attach an image"
          next
        end

        image_file_type = attachment.filename.match(/\.(?<type>png|jpg|jpeg)$/)[:type]

        event.message.reply! "Starting upscale, this can take a while"

        Tempfile.create(["2cho", ".#{image_file_type}"], "tmp/input") do |input_file|
          input_file.write HTTParty.get(attachment.url).body

          output_file_path = File.join("tmp", "output", "#{File.basename(input_file, ".*")}.png")

          success = upscale_image input_file.path, output_file_path

          unless success
            event.message.reply! "Something went wrong"
            next
          end

          output_file = File.new(output_file_path)

          if file_too_big? output_file
            url = move_file_to_storage(output_file)

            event.message.reply! url
          else
            event.message.reply!(
              success_messages,
              attachments: [output_file]
            )

            File.delete(output_file)
          end
        end
      end
    end

    private

    def success_messages
      [
        "I got you covered!",
        "Here you go!",
        "Enjoy!"
      ].sample
    end

    def upscale_image(input_file_path, output_file_path)
      _stdout, stderr, status = Open3.capture3(
        "#{ENV["ESRGAN_HOME"]}/realesrgan-ncnn-vulkan -i #{input_file_path} -o #{output_file_path} -s 2"
      )

      if status.exitstatus != 0
        puts stderr
        false
      else
        true
      end
    end

    def file_too_big?(file)
      (file.size.to_f / 1024000) > 8
    end

    def move_file_to_storage(file)
      folder = Date.today.strftime("%Y%m%d")

      if !Dir.exist?(File.join(ENV["WEBSERVER_HOME"], folder))
        Dir.mkdir File.join(ENV["WEBSERVER_HOME"], folder)
      end

      server_file_path = File.join(folder, File.basename(file))

      File.rename(file, File.join(ENV["WEBSERVER_HOME"], server_file_path))

      "https://#{ENV["URL_BASE"]}/#{server_file_path}"
    end
  end
end
