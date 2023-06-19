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

      bot.mention do |event|
        next unless server_whitelisted! event
        next unless channel_allowed_for_server! event

        TwoCho::UpscaleRequest.new(event).run
      end

      bot.message with_text: "Ping" do |event|
        next unless server_whitelisted! event, message: false
        next unless channel_allowed_for_server! event, message: false

        if Settings.development?
          event.message.reply! "Pong, but from development"
        else
          event.message.reply! "Pong"
        end
      end

      bot.message with_text: "Ruby" do |event|
        next unless server_whitelisted! event, message: false
        next unless channel_allowed_for_server! event, message: false

        event.message.reply! RUBY_VERSION
      end
    end

    def server_whitelisted!(event, message: true)
      if allowed_servers.include? event.server.id
        true
      else
        event.respond "This server is not whitelisted in the config" if message
        false
      end
    end

    def channel_allowed_for_server!(event, message: true)
      server_channels = TwoCho::Config
        .discord
        .servers
        .find do |server|
          server["id"] == event.server.id
        end["channels"]

      ok = server_channels
        .include? event.channel.name

      if !ok
        event.message.reply! "I cannot upscale images in this channel. The allowed channels for this server are:\n#{server_channels_to_message(event.server.id, server_channels)}" if message
      end

      ok
    end

    def allowed_servers
      @_allowed_servers ||= TwoCho::Config
        .discord
        .servers
        .map do |server|
          server["id"]
        end
    end

    def server_channels_to_message(server_channels)
      server_channels.map do |channel|
        "\`#{channel}\`"
      end.join("\n")
    end
  end
end
