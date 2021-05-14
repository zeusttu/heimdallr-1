# frozen_string_literal: true

require 'date'

require 'discordrb'

module Heimdallr
  PERM_R = Discordrb::Permissions.new
  PERM_R.can_read_messages = true
  PERM_R.can_read_message_history = true

  PERM_W = Discordrb::Permissions.new
  PERM_W.can_add_reactions = true
  PERM_W.can_send_messages = true

  PERM_RW = Discordrb::Permissions.new
  PERM_RW.can_read_messages = true
  PERM_RW.can_read_message_history = true
  PERM_RW.can_add_reactions = true
  PERM_RW.can_send_messages = true

  class ExquisiteCorpse
    @@all = {}

    def initialize(server, name)
      @server = server
      @name = name
      @category = nil
    end

    def self.all(server)
      @@all[server.id] = {} unless @@all.include? server.id

      ecs = @@all[server.id]
      categories = server.categories.filter { |cat| cat.name.start_with? 'ec-' }
      names = categories.map { |cat| cat.name[3..] }
      missing = names.filter { |name| !ecs.include? name }
      missing.each { |name| ecs[name] = ExquisiteCorpse.new server, name }
      ecs
    end

    def as_member(user)
      if user.instance_of? Discordrb::Member
        member
      elsif user.instance_of? Discordrb::User
        @server.member(user.id)
      elsif user.instance_of? String
        @server.member Integer(user.tr('<>@!', '    ').strip)
      else
        raise TypeError, "Member #{user} of unknown type #{user.class}."
      end
    end
    private :as_member

    def create_main_channels(
      channel_category, created_participant_role, created_viewer_role, reason
    )
      everyone = everyone_role
      @server.create_channel(
        'ec-general',
        topic: 'Meta discussions about the exquisite corpse. No spoilers!',
        parent: channel_category,
        reason: reason,
        permission_overwrites: [
          Discordrb::Overwrite.new(everyone, deny: PERM_RW),
          Discordrb::Overwrite.new(created_participant_role, allow: PERM_RW)
        ]
      )
      @server.create_channel(
        'ec-result',
        topic: 'The resulting story.',
        parent: channel_category,
        reason: reason,
        permission_overwrites: [
          Discordrb::Overwrite.new(everyone, deny: PERM_RW),
          Discordrb::Overwrite.new(created_viewer_role, allow: PERM_R)
        ]
      )
    end
    private :create_main_channels

    def create_writing_channels(channel_category, participants, reason)
      everyone = everyone_role
      prev = participants.last
      participants.each do |participant|
        @server.create_channel(
          "#{prev.display_name} -> #{participant.display_name}",
          topic: "Story bits written by #{prev.display_name}.",
          parent: channel_category,
          reason: reason,
          permission_overwrites: [
            Discordrb::Overwrite.new(everyone, deny: PERM_RW),
            Discordrb::Overwrite.new(prev, allow: PERM_RW),
            Discordrb::Overwrite.new(participant, allow: PERM_R)
          ]
        )
        prev = participant
      end
    end
    private :create_writing_channels

    def category
      if @category.nil?
        categories = @server.categories.filter do |cat|
          cat.name == "ec-#{@name}"
        end
        unless categories.one?
          names = @server.categories.map(&:name)
          raise "Exquisit Corpse's channel category 'ec-#{@name}' not found in #{names}."
        end

        @category = categories.first
      end
      @category
    end
    private :category

    def result_channel
      result_channels = category.children.filter do |channel|
        channel.name == 'ec-result'
      end
      raise "Exquisit Corpse's result channel '#{@name}.ec-result' not found." \
        unless result_channels.one?

      result_channels.first
    end
    private :result_channel

    def participant_role
      participant_roles = @server.roles.filter do |role|
        role.name == "ec-#{@name}-participant"
      end
      unless participant_roles.one?
        raise(
          "Exquisit Corpse's participant role 'ec-#{@name}-participant' not found."
        )
      end
      participant_roles.first
    end
    private :participant_role

    def viewer_role
      viewer_roles = @server.roles.filter do |role|
        role.name == "ec-#{@name}-viewer"
      end
      raise "Exquisit Corpse's viewer role 'ec-#{@name}-viewer' not found." \
        unless viewer_roles.one?

      viewer_roles.first
    end
    private :viewer_role

    def everyone_role
      everyone_roles = @server.roles.filter { |role| role.name == '@everyone' }
      raise '@everyone not found' unless everyone_roles.one?

      everyone_roles.first
    end

    def writing_channels
      category.children.filter do |channel|
        !%w[ec-general ec-result].include? channel.name
      end
    end
    private :writing_channels

    def register(bot)
      dest = result_channel
      writing_channels.each do |channel|
        bot.message(in: channel) do |event|
          dest.send_message event.content
        end
      end
    end

    def start(participants)
      reason = "Exquisite corpse '#{@name}' started at #{Date.today.iso8601}"
      participants = participants.map { |participant| as_member participant }

      created_viewer_role = @server.create_role(
        name: "ec-#{@name}-viewer", reason: reason
      )
      created_participant_role = @server.create_role(
        name: "ec-#{@name}-participant", reason: reason
      )
      participants.each do |participant|
        participant.add_role created_participant_role, reason: reason
      end

      channel_category = @server.create_channel(
        "ec-#{@name}",
        :category,
        reason: reason
      )
      create_main_channels(
        channel_category, created_participant_role, created_viewer_role, reason
      )
      create_writing_channels channel_category, participants, reason
    end

    def enter_editing_phase
      reason = "Exquisite corpse '#{@name}' entered editing phase at #{Date.today.iso8601}"

      writing_channels.each { |channel| channel.delete reason: reason }
      result_channel.define_overwrite participant_role, PERM_RW, reason: reason
    end

    def finalise
      reason = "Exquisite corpse '#{@name}' finalised at #{Date.today.iso8601}"

      channel = result_channel
      channel.delete_overwrite participant_role, reason: reason
      channel.delete_overwrite viewer_role, reason: reason
      viewer_role.delete reason: reason
      channel.define_overwrite everyone_role, PERM_R, PERM_W, reason: reason
    end

    def remove
      reason = "Exquisite corpse '#{@name}' removed at #{Date.today.iso8601}"
      channels = category.children
      role_names = ["ec-#{@name}-participant", "ec-#{@name}-viewer"]
      roles = @server.roles.filter { |role| role_names.include? role.name }

      roles.each { |role| role.delete reason: reason }
      channels.each { |channel| channel.delete reason: reason }
      category.delete reason: reason
      @@all.delete @name
    end
  end
end
