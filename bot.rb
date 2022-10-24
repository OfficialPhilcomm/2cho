require "pry"
require "open3"
require "dotenv"
require "httparty"
require "tempfile"
require "discordrb"

Dotenv.load

bot = Discordrb::Bot.new(token: ENV["TOKEN"])

ESRGAN_HOME = ENV["ESRGAN_HOME"]

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

  Tempfile.create(["2cho", ".#{image_file_type}"], "tmp/input") do |input_file|
    input_file.write HTTParty.get(attachment.url).body

    event.message.reply! "Starting upscale, this can take a while"

    _stdout, stderr, status = Open3.capture3(
      "python3 #{ESRGAN_HOME}/inference_realesrgan.py -n RealESRGAN_x4plus -i #{input_file.path} -o tmp/output --fp32 --ext png --suffix \"\""
    )

    if status.exitstatus != 0
      event.message.reply! "Something went wrong"
      puts stderr
    else
      output_file_name = "#{File.basename(input_file, ".*")}.png"

      output_file = File.new(File.join("tmp", "output", output_file_name))

      messages = [
        "I got you covered!",
        "Here you go!",
        "Enjoy!"
      ]

      event.message.reply!(
        messages.sample,
        attachments: [output_file]
      )

      File.delete(output_file)
    end
  end
end

bot.run
