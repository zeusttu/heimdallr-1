defmodule Heimdallr.Application do
  use Application

  @impl true
  @spec start(
          Application.start_type(),
          term()
        ) :: {:ok, pid()} | {:ok, pid(), Application.state()} | {:error, term()}
  def start(_type, _args) do
    children = [
      Heimdallr.ConsumerSupervisor
    ]

    options = [strategy: :rest_for_one, name: Heimdallr.Supervisor]
    Supervisor.start_link(children, options)
  end
end
