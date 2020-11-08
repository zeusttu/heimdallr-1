require "heimdallr/version"

require "discordrb"
require "sqlite3"

module Heimdallr
  bot = Discordrb::Commands::CommandBot.new token: ENV["DISCORD_BOT_TOKEN"], prefix: ","

  begin
    db = SQLite3::Database.new "bot.db"
    db.results_as_hash = true
    db.execute <<-SQL
      create table if not exists faq (
        topic text,
        description text
      );
    SQL
  rescue SQLite3::Exception => exc
    bot.log_exception exc
    exit
  end

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

  bot.message(start_with: "t!") do |event|
    event.respond "I'm terribly sorry, we don't have Tatsumaki here. Try `,help`."
  end

  bot.command(:faq, description: "Get a FAQ entry", usage: ",faq <topic>") do |event|
    _command, topic = event.content.split
    return "Please provide a topic. See `,help faq`" unless topic
    begin
      description = db.get_first_value "select description from faq where topic=?", topic
      description || "Not found!"
    rescue SQLite3::Exception => exc
      bot.log_exception exc
      "Oof ouch, an error occurred. Please let sarna know."
    end
  end

  bot.command(
    :faqadd,
    description: "Set a FAQ entry (staff only)",
    usage: ",faqadd <topic> <description>"
  ) do |event|
    staff = bot
      .servers.values.first
      .roles.select { |role|
      ["Moderator", "Assistant Moderator", "Helper"].include? role.name
    }
    return "You're not staff!" unless event.author.roles.any? { |role| staff.include? role }

    _command, topic, description = event.content.split(/\s+/, 3)
    return "Please provide a topic. See `,help faqadd`" unless topic
    return "Please provide a description. See `,help faqadd`" unless description
    begin
      db.execute "insert into faq values ( ?, ? )", topic, description
      "Done :)"
    rescue SQLite3::Exception => exc
      bot.log_exception exc
      "Oof ouch, an error occurred. Please let sarna know."
    end
  end

  bot.command(
    :faqrem,
    description: "Remove a FAQ entry (staff only)",
    usage: ",faqrem <topic>"
  ) do |event|
    staff = bot
      .servers.values.first
      .roles.select { |role|
      ["Moderator", "Assistant Moderator", "Helper"].include? role.name
    }
    return "You're not staff!" unless event.author.roles.any? { |role| staff.include? role }

    _command, topic = event.content.split
    return "Please provide a topic. See `,help faqrem`" unless topic
    begin
      description = db.get_first_value "select description from faq where topic=?", topic
      return "Not found!" unless description
      db.execute "delete from faq where topic=?", topic
      "Done :)"
    rescue SQLite3::Exception => exc
      bot.log_exception exc
      "Oof ouch, an error occurred. Please let sarna know."
    end
  end

  bot.run
end
