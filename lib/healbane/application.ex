defmodule Healbane.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      HealbaneWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:healbane, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Healbane.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Healbane.Finch},
      # Start a worker by calling: Healbane.Worker.start_link(arg)
      # {Healbane.Worker, arg},
      Healbane.WatchServer,
      # Start to serve requests, typically the last entry
      HealbaneWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Healbane.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    HealbaneWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
