defmodule Heimdallr.Consumer do
  alias Heimdallr.Consumer.{
    MessageCreate,
    GuildMemberAdd,
    GuildMemberRemove
  }

  use Nostrum.Consumer

  @spec start_link :: Supervisor.on_start()
  def start_link do
    Consumer.start_link(__MODULE__, max_restarts: 0)
  end

  @impl true
  @spec handle_event(Nostrum.Consumer.event()) :: any()
  def handle_event({:MESSAGE_CREATE, message, _ws_state}) do
    MessageCreate.handle(message)
  end

  def handle_event({:GUILD_MEMBER_ADD, {guild_id, member}, _ws_state}) do
    GuildMemberAdd.handle(guild_id, member)
  end

  def handle_event({:GUILD_MEMBER_REMOVE, {guild_id, member}, _ws_state}) do
    GuildMemberRemove.handle(guild_id, member)
  end

  # default event handler
  def handle_event(_event) do
    :noop
  end
end
