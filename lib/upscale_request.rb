require "time"
require "open3"
require "httparty"
require "tempfile"
require "fileutils"
require_relative "config"
require_relative "settings"

module TwoCho
  class UpscaleRequest
    attr_reader :discord_event

    def initialize(discord_event)
      @discord_event = discord_event
    end

    def run
      return unless any_attachments!
      return unless one_attachment!
      return unless attachment_is_image!
      return if image_is_too_big!

      process_upscale_request
    end

    private

    def any_attachments!
      if combined_attachments.any?
        true
      else
        discord_event.message.reply! "I can only upscale an image if you attach one to the message you ping me in"
        false
      end
    end

    def one_attachment!
      if combined_attachments.one?
        true
      else
        discord_event.message.reply! "Please send only one image per message for now (this is being worked on)"
        false
      end
    end

    def attachment_is_image!
      attachment = combined_attachments.first

      if attachment.image?
        true
      else
        discord_event.message.reply! "Please attach an image"
        false
      end
    end

    def image_is_too_big!
      image = combined_attachments.first

      if Settings.development?
        discord_event.message.reply! [
          "Width: #{image.width} Height: #{image.height}",
          "Total pixel count: #{image.width * image.height}"
        ].join("\n")
      end

      if image.width * image.height > 8294400
        discord_event.message.reply! "Your image is estimated to be above 4k. Due to processing limitations, I cannot upscale your image."
        true
      else
        false
      end
    end

    def process_upscale_request
      attachment = combined_attachments.first
      image_file_type = attachment.filename.match(/\.(?<type>png|jpg|jpeg)$/)[:type]
      discord_event.message.reply! "Starting upscale, this can take a while"

      Tempfile.create(["2cho", ".#{image_file_type}"], "tmp/input") do |input_file|
        input_file.write HTTParty.get(attachment.url).body

        output_file_path = File.join(Dir.pwd, "tmp", "output", "#{File.basename(input_file, ".*")}.png")

        success = upscale_image input_file.path, output_file_path

        unless success
          discord_event.message.reply! "Something went wrong"
          next
        end

        output_file = File.new(output_file_path)

        if file_too_big? output_file
          url = move_file_to_storage(output_file)

          discord_event.message.reply! url
        else
          discord_event.message.reply!(
            success_messages,
            attachments: [output_file]
          )

          File.delete(output_file)
        end
      end
    end

    def upscale_image(input_file_path, output_file_path)
      if Settings.production?
        _stdout, stderr, status = Open3.capture3(
          "#{TwoCho::Config.esrgan.executable} -i #{input_file_path} -o #{output_file_path} -s 2"
        )

        if status.exitstatus != 0
          puts "Something went wrong. Error: #{stderr}"
          false
        else
          true
        end
      else
        FileUtils.cp(input_file_path, output_file_path)
        true
      end
    end

    def success_messages
      [
        "I got you covered!",
        "Here you go!",
        "Enjoy!"
      ].sample
    end

    def file_too_big?(file)
      (file.size.to_f / 1024000) > 8
    end

    def move_file_to_storage(file)
      if Settings.production?
        folder = Date.today.strftime("%Y%m%d")

        if !Dir.exist?(File.join(TwoCho::Config.webserver.home, folder))
          Dir.mkdir File.join(TwoCho::Config.webserver.home, folder)
        end

        server_file_path = File.join(folder, File.basename(file))

        FileUtils.mv(file, File.join(TwoCho::Config.webserver.home, server_file_path))

        "#{TwoCho::Config.webserver.use_https ? "https" : "http"}://#{TwoCho::Config.webserver.domain}/#{server_file_path}"
      else
        "http://swhost.no/test.png"
      end
    end

    def combined_attachments
      @_combined_attachments ||= begin
        attachments = discord_event.message.attachments

        if discord_event.message.reply?
          attachments += discord_event.message.referenced_message.attachments
        end

        attachments
      end
    end
  end
end
