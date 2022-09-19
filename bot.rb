require "pry"
require "dotenv"
require "discordrb"

Dotenv.load

bot = Discordrb::Bot.new(token: ENV["TOKEN"])

bot.message in: "#testies" do |event|
  event.respond "you mfer!"
end

bot.mention do |event|
  event.respond "Who dares to disturb me?"
end

bot.run
