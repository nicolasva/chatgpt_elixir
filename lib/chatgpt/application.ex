defmodule Chatgpt.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    redis_url = Application.get_env(:chatgpt, :redis_url, "redis://localhost:6379/0")

    children = [
      ChatgptWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:chatgpt, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Chatgpt.PubSub},
      {Redix, {redis_url, [name: :redix]}},
      # GenServers du chatbot (ordre important : AutoLearner charge le dataset en premier)
      Chatgpt.AutoLearner,
      Chatgpt.IntentDetector,
      Chatgpt.CompoundPhraseResolver,
      # Start to serve requests, typically the last entry
      ChatgptWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Chatgpt.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    ChatgptWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
