require "heimdallr/version"

require "discordrb"

module Heimdallr
  bot = Discordrb::Commands::CommandBot.new token: ENV["DISCORD_BOT_TOKEN"], prefix: ","

  bot.command :ping do |event|
    "pong!"
  end

  bot.member_join do |event|
    msg = <<~TEXT.strip
      :postal_horn: Greetings and welcome, #{event.user.mention}.
      Please, tell our moderators what your level of Danish is so that we may tag you accordingly.
      If you wish to be notified for any upcoming lessons, you can also get a tag granted for that.
    TEXT
    event.user.await(:"welcome_#{event.user.id}") do |welcome_event|
      sleep 10
      welcome_event.server.system_channel.send_message msg
    end
  end

  bot.member_leave do |event|
    msg = <<~TEXT.strip
      :rainbow: Farewell, #{event.user.username}. As brave as you may feel, it is dangerous beyond these halls!
    TEXT
    event.server.system_channel.send_message msg
  end

  bot.run
end
