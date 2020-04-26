defmodule Heimdallr.Consumer.GuildMemberAdd do
  @moduledoc "Handles the `GUILD_MEMBER_ADD` event."

  alias Nostrum.Api

  @spec handle(Guild.id(), Guild.Member.t()) ::
          Nostrum.Api.error() | {:ok, Nostrum.Struct.Message.t()}
  def handle(guild_id, member) do
    message = """
    :postal_horn: Greetings and welcome, #{member}.
    Please, tell our moderators what your level of Danish is so that we may tag you accordingly.
    If you wish to be notified for any upcoming lessons, you can also get a tag granted for that.
    """

    guild = Api.get_guild!(guild_id)
    system_channel_id = guild.system_channel_id

    Process.sleep(10_000)
    Api.create_message(system_channel_id, message)
  end
end
