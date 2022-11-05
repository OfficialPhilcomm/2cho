require "pry"
require "time"
require "open3"
require "dotenv"
require "httparty"
require "tempfile"
require "discordrb"
require_relative "config"

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
      @bot = Discordrb::Bot.new(token: TwoCho::Config.discord.token)

      bot.mention in: "#screenshots" do |event|
        next unless server_whitelisted! event
        next unless any_attachments! event
        next unless one_attachment! event
        next unless attachment_is_image! event

        attachment = event.message.attachments.first

        image_file_type = attachment.filename.match(/\.(?<type>png|jpg|jpeg)$/)[:type]

        event.message.reply! "Starting upscale, this can take a while"

        Tempfile.create(["2cho", ".#{image_file_type}"], "tmp/input") do |input_file|
          input_file.write HTTParty.get(attachment.url).body

          output_file_path = File.join(Dir.pwd, "tmp", "output", "#{File.basename(input_file, ".*")}.png")

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
        "#{TwoCho::Config.esrgan.home}/realesrgan-ncnn-vulkan -i #{input_file_path} -o #{output_file_path} -s 2"
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

      if !Dir.exist?(File.join(TwoCho::Config.webserver.home, folder))
        Dir.mkdir File.join(TwoCho::Config.webserver.home, folder)
      end

      server_file_path = File.join(folder, File.basename(file))

      File.rename(file, File.join(TwoCho::Config.webserver.home, server_file_path))

      "https://#{TwoCho::Config.webserver.domain}/#{server_file_path}"
    end

    def server_whitelisted!(event)
      if TwoCho::Config.discord.allowed_servers.include? event.server.id
        true
      else
        event.respond "This server is not whitelisted in the config"
        false
      end
    end

    def any_attachments!(event)
      if event.message.attachments.any?
        true
      else
        event.respond "I can only upscale an image if you attach one to the message you ping me in"
        false
      end
    end

    def one_attachment!(event)
      if event.message.attachments.one?
        true
      else
        event.respond "Please send only one image per message for now (this is being worked on)"
        false
      end
    end

    def attachment_is_image!(event)
      attachment = event.message.attachments.first

      if attachment.image?
        true
      else
        event.respond "Please attach an image"
        false
      end
    end
  end
end
