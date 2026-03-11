defmodule Chatgpt.CachedSearch do
  @moduledoc """
  Décorateur de cache Redis autour de n'importe quel service de recherche.
  Équivalent du CachedSearch Ruby.

  Usage :

      Chatgpt.CachedSearch.search("wikipedia", "capitale de la France", fn ->
        WikipediaService.search("capitale de la France")
      end)

      # Avec un TTL personnalisé (en secondes) :
      Chatgpt.CachedSearch.search("weather", query, fn -> WeatherService.fetch(query) end, ttl: 300)
  """

  require Logger

  @default_ttl 3_600

  @doc """
  Cherche `query` dans le cache Redis. En cas de miss, exécute `fun` et met en cache le résultat.
  """
  def search(service_name, query, fun, opts \\ []) do
    ttl = Keyword.get(opts, :ttl, @default_ttl)
    key = cache_key(service_name, query)

    case get(key) do
      {:ok, cached} ->
        Logger.debug("[CachedSearch] hit #{key}")
        cached

      :miss ->
        result = fun.()
        put(key, result, ttl)
        result
    end
  end

  # ---------------------------------------------------------------------------
  # Privé
  # ---------------------------------------------------------------------------

  defp cache_key(service_name, query) do
    hash = :crypto.hash(:md5, query) |> Base.encode16(case: :lower)
    "search:#{service_name}:#{hash}"
  end

  defp get(key) do
    case Redix.command(:redix, ["GET", key]) do
      {:ok, nil} ->
        :miss

      {:ok, json} ->
        {:ok, Jason.decode!(json)}

      {:error, reason} ->
        Logger.warning("[CachedSearch] Redis GET error: #{inspect(reason)}")
        :miss
    end
  end

  defp put(key, value, ttl) do
    case Redix.command(:redix, ["SETEX", key, ttl, Jason.encode!(value)]) do
      {:ok, _} -> :ok
      {:error, reason} -> Logger.warning("[CachedSearch] Redis SETEX error: #{inspect(reason)}")
    end
  end
end
