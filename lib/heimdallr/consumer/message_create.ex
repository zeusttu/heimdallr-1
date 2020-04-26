defmodule Heimdallr.Consumer.MessageCreate do
  @moduledoc "Handles the `MESSAGE_CREATE` event."

  alias Nostrum.Api

  @spec handle(Nostrum.Struct.Message.t()) ::
          Nostrum.Api.error() | {:ok, Nostrum.Struct.Message.t()} | nil
  def handle(message) do
    case message.content do
      ",sleep" ->
        Api.create_message(message.channel_id, "Going to sleep...")
        Process.sleep(5000)
        Api.create_message(message.channel_id, "I'm awake again")

      ",ping" ->
        Api.create_message(message.channel_id, "pong!")

      ",crash" ->
        Api.create_message(message.channel_id, "Oh no I've crashed :rolling_eyes:")
        raise "crashed via ,crash"

      _ ->
        :ignore
    end
  end
end
