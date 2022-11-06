require "pry"
require "time"
require "discordrb"
require_relative "config"
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
        TwoCho::UpscaleRequest.new(event).run
      end
    end
  end
end
