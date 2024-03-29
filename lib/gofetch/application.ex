defmodule Gofetch.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Starts a worker by calling: Gofetch.Worker.start_link(arg)
      # {Gofetch.Worker, arg}
      %{
        id: Gofetch.Server,
        start: {Gofetch.Server, :start_link, [Gofetch.App, 8080]}
      }
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Gofetch.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
