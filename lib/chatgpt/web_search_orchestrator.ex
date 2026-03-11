defmodule Chatgpt.WebSearchOrchestrator do
  @moduledoc """
  Orchestre les différentes sources de recherche web :
  Tavily → DuckDuckGo API → Wikipedia → DuckDuckGo HTML.
  Implémente des stratégies de repli (synonymes, définitions, correction).
  """

  require Logger

  @doc "Recherche avec stratégies de repli en cascade (avec cache Redis 1h)."
  def search(query) do
    Chatgpt.CachedSearch.search("web_search", query, fn -> do_search(query) end)
  end

  defp do_search(query) do
    enriched_query = Chatgpt.CompoundPhraseResolver.resolve(query)

    if enriched_query != String.downcase(query) do
      Logger.info(
        "[WebSearchOrchestrator] Expressions composées : '#{query}' → '#{enriched_query}'"
      )
    end

    result = if enriched_query != String.downcase(query), do: search_direct(enriched_query)

    result = result || search_direct(query)

    if result do
      result
    else
      keywords = Chatgpt.KeywordExtractor.extract(enriched_query)

      if Enum.empty?(keywords) do
        nil
      else
        Logger.info("[WebSearchOrchestrator] Recherche directe échouée, essai synonymes...")
        result = search_with_synonyms(enriched_query, keywords)

        result =
          if result && Chatgpt.WikipediaService.relevant?(result, query) do
            result
          else
            Logger.info("[WebSearchOrchestrator] Synonymes échoués, essai définitions...")
            r = search_with_definitions(enriched_query, keywords)
            if r && Chatgpt.WikipediaService.relevant?(r, query), do: r
          end

        result =
          if result do
            result
          else
            Logger.info("[WebSearchOrchestrator] Définitions échouées, essai correction...")
            r = search_with_spelling_correction(enriched_query, keywords)
            if r && Chatgpt.WikipediaService.relevant?(r, query), do: r
          end

        result =
          if result do
            result
          else
            Logger.info("[WebSearchOrchestrator] Correction échouée, essai Wikipedia individuel...")
            extract = Chatgpt.WikipediaService.wiki_search_individual("fr", keywords, enriched_query)

            if extract do
              full_result = "D'après Wikipedia : #{extract}"
              if Chatgpt.WikipediaService.relevant?(full_result, query), do: full_result
            end
          end

        result
      end
    end
  rescue
    e ->
      Logger.error("[WebSearchOrchestrator] Erreur : #{Exception.message(e)}")
      nil
  end

  defp search_direct(query) do
    Chatgpt.TavilyService.search(query) ||
      Chatgpt.DuckDuckGoService.search_api(query) ||
      Chatgpt.WikipediaService.search(query) ||
      Chatgpt.DuckDuckGoService.search_web(query)
  rescue
    e ->
      Logger.error("[WebSearchOrchestrator] Erreur directe : #{Exception.message(e)}")
      nil
  end

  defp search_relaxed(query) do
    Chatgpt.TavilyService.search(query) ||
      Chatgpt.DuckDuckGoService.search_api(query) ||
      Chatgpt.WikipediaService.search_relaxed(query) ||
      Chatgpt.DuckDuckGoService.search_web(query)
  rescue
    e ->
      Logger.error("[WebSearchOrchestrator] Erreur relaxée : #{Exception.message(e)}")
      nil
  end

  defp search_with_synonyms(query, keywords) do
    Enum.find_value(keywords, fn word ->
      synonyms = Chatgpt.WiktionaryService.find_synonyms(word)

      if synonyms != [] do
        Logger.info(
          "[WebSearchOrchestrator] Synonymes de '#{word}' : #{Enum.join(synonyms, ", ")}"
        )

        Enum.find_value(synonyms, fn syn ->
          new_query = String.replace(query, ~r/#{Regex.escape(word)}/i, syn)
          search_relaxed(new_query)
        end)
      end
    end)
  rescue
    e ->
      Logger.error("[WebSearchOrchestrator] Erreur synonymes : #{Exception.message(e)}")
      nil
  end

  defp search_with_definitions(_query, keywords) do
    keywords
    |> Enum.sort_by(&(-String.length(&1)))
    |> Enum.find_value(fn word ->
      definition = Chatgpt.WiktionaryService.definition(word)

      if definition do
        Logger.info(
          "[WebSearchOrchestrator] Définition de '#{word}' : #{String.slice(definition, 0, 80)}..."
        )

        def_keywords = Chatgpt.KeywordExtractor.extract(definition) |> Enum.take(2)

        if def_keywords != [] do
          other_keywords = Enum.reject(keywords, &(&1 == word))
          nq = Enum.join(other_keywords ++ [List.first(def_keywords)], " ")
          Logger.info("[WebSearchOrchestrator] Recherche enrichie : '#{nq}'")
          result = search_relaxed(nq)

          result ||
            if length(def_keywords) > 1 do
              nq2 = Enum.join(other_keywords ++ [Enum.at(def_keywords, 1)], " ")
              search_relaxed(nq2)
            end
        end
      end
    end)
  rescue
    e ->
      Logger.error("[WebSearchOrchestrator] Erreur définitions : #{Exception.message(e)}")
      nil
  end

  defp search_with_spelling_correction(_query, keywords) do
    corrected =
      Enum.map(keywords, fn w -> Chatgpt.WiktionaryService.correct_spelling(w) || w end)

    if corrected == keywords do
      nil
    else
      corrected_query = Enum.join(corrected, " ")
      Logger.info(
        "[WebSearchOrchestrator] Correction : #{Enum.join(keywords, " ")} → #{corrected_query}"
      )
      search_direct(corrected_query)
    end
  rescue
    e ->
      Logger.error("[WebSearchOrchestrator] Erreur correction : #{Exception.message(e)}")
      nil
  end
end
