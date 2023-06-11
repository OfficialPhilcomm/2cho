require "pry"
require "time"
require "discordrb"
require_relative "config"
require_relative "settings"
require_relative "upscale_request"

module TwoCho
  class UpscaleBot
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

        TwoCho::UpscaleRequest.new(event).run
      end

      channels = Config
        .discord
        .channels
        .map do |channel|
          "##{channel}"
        end

      bot.message with_text: "Ping", in: channels do |event|
        if Settings.development?
          event.message.reply! "Pong, but from development"
        else
          event.message.reply! "Pong"
        end
      end

      bot.message with_text: "Ruby", in: "#screenshots" do |event|
        event.message.reply! RUBY_VERSION
      end
    end

    def server_whitelisted!(event)
      if TwoCho::Config.discord.allowed_servers.include? event.server.id
        true
      else
        event.respond "This server is not whitelisted in the config"
        false
      end
    end
  end
end
