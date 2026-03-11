defmodule Chatgpt.DuckDuckGoService do
  @moduledoc """
  Client DuckDuckGo : API JSON et scraping HTML.
  """

  require Logger

  @doc "Recherche via l'API DuckDuckGo (JSON, sans clé)."
  def search_api(query) do
    keywords = Chatgpt.KeywordExtractor.extract(query)

    if Enum.empty?(keywords) do
      nil
    else
      search_term = URI.encode(Enum.join(keywords, " "), &URI.char_unreserved?/1)
      url = "https://api.duckduckgo.com/?q=#{search_term}&format=json&no_html=1&skip_disambig=1&lang=fr"

      case Req.get(url, receive_timeout: 10_000) do
        {:ok, %{status: 200, body: body}} ->
          abstract = Map.get(body, "AbstractText", "")
          answer = Map.get(body, "Answer", "")
          topics = Map.get(body, "RelatedTopics", [])

          cond do
            abstract != "" ->
              Chatgpt.SearchResult.from_duckduckgo(abstract) |> Chatgpt.SearchResult.format()

            answer != "" ->
              Chatgpt.SearchResult.from_duckduckgo(answer) |> Chatgpt.SearchResult.format()

            is_list(topics) and topics != [] ->
              case List.first(topics) do
                %{"Text" => text} when text != "" ->
                  Chatgpt.SearchResult.from_duckduckgo(text) |> Chatgpt.SearchResult.format()

                _ ->
                  nil
              end

            true ->
              nil
          end

        _ ->
          nil
      end
    end
  rescue
    e ->
      Logger.error("[DuckDuckGoService] Erreur API : #{Exception.message(e)}")
      nil
  end

  @doc "Scrape les résultats HTML de DuckDuckGo."
  def search_web(query) do
    keywords = Chatgpt.KeywordExtractor.extract(query)

    if Enum.empty?(keywords) do
      nil
    else
      search_term = URI.encode(Enum.join(keywords, " "), &URI.char_unreserved?/1)
      url = "https://html.duckduckgo.com/html/?q=#{search_term}"

      case Req.get(url,
             headers: [
               {"user-agent",
                "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"}
             ],
             connect_options: [timeout: 5_000],
             receive_timeout: 10_000
           ) do
        {:ok, %{status: 200, body: body}} ->
          html = if is_binary(body), do: body, else: inspect(body)

          if String.contains?(html, "anomaly-modal") or String.contains?(html, "captcha") do
            nil
          else
            results =
              Regex.scan(~r/<a rel="nofollow" class="result__a" href="[^"]*">(.*?)<\/a>/s, html)
              |> Enum.map(fn [_, match] ->
                match
                |> String.replace(~r/<[^>]*>/, "")
                |> String.replace("&amp;", "&")
                |> String.replace("&#x27;", "'")
                |> String.replace("&quot;", "\"")
                |> String.trim()
              end)
              |> Enum.reject(&(&1 == ""))

            if Enum.empty?(results) do
              nil
            else
              "Résultats DuckDuckGo :\n#{results |> Enum.take(3) |> Enum.join("\n")}"
            end
          end

        _ ->
          nil
      end
    end
  rescue
    e ->
      Logger.error("[DuckDuckGoService] Erreur Web : #{Exception.message(e)}")
      nil
  end
end
