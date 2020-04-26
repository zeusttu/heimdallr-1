defmodule Heimdallr.Consumer.GuildMemberRemove do
  @moduledoc "Handles the `GUILD_MEMBER_REMOVE` event."

  alias Nostrum.Api

  @spec handle(Guild.id(), Guild.Member.t()) ::
          Nostrum.Api.error() | {:ok, Nostrum.Struct.Message.t()}
  def handle(guild_id, member) do
    message = """
    :rainbow: Farewell, #{member.user.username}. As brave as you may feel, it is dangerous beyond these halls!
    """

    guild = Api.get_guild!(guild_id)
    system_channel_id = guild.system_channel_id

    Api.create_message(system_channel_id, message)
  end
end
