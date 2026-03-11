defmodule Chatgpt.TavilyService do
  @moduledoc """
  Client pour l'API de recherche Tavily.
  """

  require Logger

  @doc "Recherche via l'API Tavily."
  def search(query) do
    api_key = System.get_env("TAVILY_API_KEY")

    if is_nil(api_key) or api_key == "" do
      nil
    else
      keywords = Chatgpt.KeywordExtractor.extract(query)

      if Enum.empty?(keywords) do
        nil
      else
        payload = %{
          query: Enum.join(keywords, " "),
          search_depth: "basic",
          max_results: 3,
          include_answer: false,
          country: "France"
        }

        case Req.post("https://api.tavily.com/search",
               json: payload,
               auth: {:bearer, api_key},
               connect_options: [timeout: 5_000],
               receive_timeout: 10_000
             ) do
          {:ok, %{status: 200, body: body}} ->
            results = Map.get(body, "results", [])

            if Enum.empty?(results) do
              nil
            else
              content =
                results
                |> Enum.take(3)
                |> Enum.map(fn item ->
                  title = item["title"] || ""
                  text = (item["content"] || "") |> String.replace("\n", " ")
                  "#{title} : #{text}"
                end)
                |> Enum.join("\n")

              Chatgpt.SearchResult.from_tavily(content) |> Chatgpt.SearchResult.format()
            end

          _ ->
            nil
        end
      end
    end
  rescue
    e ->
      Logger.error("[TavilyService] Erreur : #{Exception.message(e)}")
      nil
  end
end
