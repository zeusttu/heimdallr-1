require "heimdallr/version"

require "discordrb"

module Heimdallr
  bot = Discordrb::Commands::CommandBot.new token: ENV["DISCORD_BOT_TOKEN"], prefix: ","

  bot.command(:ping, description: "Check if bot is responsive.", usage: ",ping") do |event|
    "pong!"
  end

  bot.command(:roles, description: "Display available roles.", usage: ",roles") do |event|
    tongue_twisters = [
      "Fisker Frits fisker friske fisk",
      "Var det Varde, hva? Var det, hva?",
      "Storstrømsbrosekspropriationskommissionsmedlem",
      "Hundrede pund hunpuddelhundeuld",
      "Præstens ged i degnens eng",
      "Bissens gipsbisps gipsgebis",
      "Røde rødøjede rådne ørreder"
    ]
    <<~TEXT.strip
      **List of available roles:**
      **`Beginner`**: If you're just beginning to learn Danish (A1-A2). 
      **`Intermediate`**: If you know enough to hold conversations comfortably (B1-B2).
      **`Fluent`**: If you're able to pronounce "#{tongue_twisters.sample}" (C1-C2).
      **`Native`**: Hvis du er dansk.
      **`Ping Me For Lessons`**: If you want to get notified for ~weekly lessons.
      **`Voice Chat`**: If you want to get notified for random voice-chats.
    TEXT
  end

  bot.member_join do |event|
    msg = <<~TEXT.strip
      :postal_horn: Greetings and welcome, #{event.user.mention}.
      Please, tell our moderators what your level of Danish is so that we may tag you accordingly.
      If you wish to be notified for any upcoming lessons, you can also get a tag granted for that.
    TEXT
    sleep 10
    event.server.system_channel.send_message msg
  end

  bot.member_leave do |event|
    msg = <<~TEXT.strip
      :rainbow: Farewell, #{event.user.username}. As brave as you may feel, it is dangerous beyond these halls!
    TEXT
    event.server.system_channel.send_message msg
  end

  bot.run
end
