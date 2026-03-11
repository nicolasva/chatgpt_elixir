defmodule Chatgpt.Search do
  @moduledoc """
  Context de recherche.
  Regroupe la recherche web et la météo.
  """

  alias Chatgpt.{WebSearchOrchestrator, WeatherService}

  @doc "Recherche sur le web avec stratégies de repli en cascade."
  defdelegate search(query), to: WebSearchOrchestrator

  @doc "Recherche la météo à partir d'un message."
  defdelegate weather(message), to: WeatherService, as: :search
end
