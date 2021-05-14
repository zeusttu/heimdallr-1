require "heimdallr/version"

require "json"
require "discordrb"
require "http"
require "sqlite3"
require "open-uri"

module Heimdallr
  def self.asciize_danish(s)
    replacements = {
      "æ" => "ae",
      "ø" => "oe",
      "å" => "aa"
    }
    s.gsub(Regexp.union(replacements.keys), replacements)
  end

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
      :postal_horn: Greetings and welcome, #{event.user.mention}!
      How well do you speak Danish, good visitor?
      Let us know if you wish to be notified of any upcoming lessons.
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

  bot.command(:say, description: "Get a pronunciation for a Danish phrase", usage: ",say <phrase>") do |event|
    _command, *phrase = *event.content.split
    phrase = phrase.join(" ")
    return "Please provide a phrase. See `,help say`" unless phrase
    url = "https://apicorporate.forvo.com/api2/v1.1/d6a0d68b18fbcf26bcbb66ec20739492/word-pronunciations/word/#{URI.encode_www_form_component phrase}/language/da/order/rate-desc"
    begin
      response = HTTP.timeout(5).get(url)
      return "Got an error while querying Forvo API. Sorry!" unless response.status.success?
      json = JSON.parse(response.body.to_s)
      items = json["data"]["items"]
      items.each { |item| puts "item's word: #{item["word"]}, phrase: #{phrase}" }
      items.select! { |item| item["word"] == phrase }
      if items.empty?
        "No entry found. Apologies!"
      else
        mp3_link = items.first["realmp3"]
        mp3_filename = "#{asciize_danish phrase}.mp3"
        system("wget -O '#{mp3_filename}' #{mp3_link}")
        file = File.open(mp3_filename)
        event.attach_file file
        spawn("sleep 10 && rm '#{mp3_filename}'")
        ":palms_up_together:"
      end
    rescue HTTP::Error => exc
      bot.log_exception exc
      "Oof ouch, an error occurred. Please let sarna know."
    end
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

  bot.command(
    :startec,
    description: "Start an exquisite corpse.",
    usage: ",startec <name> <participant1> <participant2> ..."
  ) do |event|
    _command, name, *participants = event.content.split
    ec = ExquisiteCorpse.new event.server, name
    ec.start participants
    ec.register bot
    "Started dxquisite corpse '#{name}'."
  end

  bot.command(
    :proceedec,
    description:
      "Finish the writing phase of an exquisite corpse and proceed to the edit phase.",
    usage: ",proceedec <name>"
  ) do |event|
    _command, name = event.content.split
    ExquisiteCorpse.all(event.server)[name].enter_editing_phase
    "Moved exquisite corpse '#{name}' on to the editing phase."
  end

  bot.command(
    :finaliseec,
    description:
      "Finalise an exquisite corpse and publish the result for the world to see.",
    usage: ",finaliseec <name>"
  ) do |event|
    _command, name = event.content.split
    ExquisiteCorpse.all(event.server)[name].finalise
    "Finalised exquisite corpse '#{name}'."
  end

  bot.command(
    :removeec,
    description: "Remove an exquisite corpse. This can not be undone.",
    usage: ",removeec <name>"
  ) do |event|
    _command, name = event.content.split
    ExquisiteCorpse.all(event.server)[name].remove
    "Removed exquisite corpse '#{name}'."
  end

  bot.ready do |event|
    bot.servers.values.each do |server|
      ExquisiteCorpse.all(server).values.each { |ec| ec.register bot }
    end
  end

  bot.server_create do |event|
    ExquisiteCorpse.all(event.server).values.each { |ec| ec.register bot }
  end

  bot.run
end
