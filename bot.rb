#!/usr/bin/env ruby
# frozen_string_literal: true

require 'discordrb'

bot = Discordrb::Bot.new token: ENV['DISCORD_BOT_TOKEN']

bot.message(content: 'ping') do |event|
  event.respond 'pong'
end

bot.run
