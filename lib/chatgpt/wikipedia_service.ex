defmodule Chatgpt.WikipediaService do
  @moduledoc """
  Service de recherche Wikipedia en français.
  Gère la détection d'intention, la désambiguïsation, et l'extraction de sections.
  """

  require Logger

  @doc "Recherche principale sur Wikipedia."
  def search(query) do
    keywords = Chatgpt.KeywordExtractor.extract(query)

    if Enum.empty?(keywords) do
      nil
    else
      query_words = Chatgpt.TextNormalizer.normalize(query)
      indicators = get_country_indicators()

      result =
        if Enum.any?(query_words, fn qw ->
             Enum.any?(indicators, fn w -> Chatgpt.SimilarityCalculator.stem_match?(qw, w) end)
           end) do
          search_country_related(query, query_words, keywords, indicators)
        end

      result =
        result ||
          if Regex.match?(~r/\b(le|la|les)\s+(plus|moins)\b/i, query) do
            list_keywords = ["liste"] ++ keywords
            Logger.info("[WikipediaService] Superlatif : #{Enum.join(list_keywords, " ")}")
            extract = wiki_search("fr", list_keywords, query)

            if extract && relevant?(extract, query) do
              Chatgpt.SearchResult.from_wikipedia(extract) |> Chatgpt.SearchResult.format()
            end
          end

      result =
        result ||
          if cast_query?(query_words) do
            film_keywords = keywords ++ ["film"]
            Logger.info("[WikipediaService] Cast+film : #{Enum.join(film_keywords, " ")}")
            extract = wiki_search("fr", film_keywords, query)
            if extract, do: Chatgpt.SearchResult.from_wikipedia(extract) |> Chatgpt.SearchResult.format()
          end

      result =
        result ||
          (fn ->
            extract = wiki_search("fr", keywords, query)

            if extract && relevant?(extract, query) do
              Chatgpt.SearchResult.from_wikipedia(extract) |> Chatgpt.SearchResult.format()
            else
              if extract, do: Logger.info("[WikipediaService] Standard non pertinent, ignoré")
              nil
            end
          end).()

      result
    end
  rescue
    e ->
      Logger.error("[WikipediaService] Erreur search : #{Exception.message(e)}")
      nil
  end

  @doc "Recherche relaxée (moins stricte sur la pertinence)."
  def search_relaxed(query) do
    keywords = Chatgpt.KeywordExtractor.extract(query)

    if Enum.empty?(keywords) do
      nil
    else
      extract = wiki_query("fr", Enum.join(keywords, " "), query, relaxed: true)
      if extract, do: Chatgpt.SearchResult.from_wikipedia(extract) |> Chatgpt.SearchResult.format()
    end
  rescue
    e ->
      Logger.error("[WikipediaService] Erreur relaxé : #{Exception.message(e)}")
      nil
  end

  @doc "Vérifie si le résultat est pertinent par rapport à la requête."
  def relevant?(extract, query) do
    if is_nil(query) or query == "" do
      true
    else
      query_kw = Chatgpt.KeywordExtractor.extract(query)

      if Enum.empty?(query_kw) or length(query_kw) <= 1 do
        true
      else
        intro = extract |> String.split(~r/[.\n]/) |> List.first("") |> String.downcase()
        intro_norm = Chatgpt.TextNormalizer.strip_accents(intro)

        matched =
          Enum.count(query_kw, fn kw ->
            String.contains?(intro_norm, Chatgpt.TextNormalizer.strip_accents(kw))
          end)

        min_needed = max(ceil(length(query_kw) * 2 / 3), 1)
        matched >= min_needed
      end
    end
  end

  @doc "Recherche Wikipedia mot-clé par mot-clé."
  def wiki_search_individual(lang, keywords, original_query \\ "") do
    keywords
    |> Enum.sort_by(&(-String.length(&1)))
    |> Enum.find_value(fn keyword ->
      wiki_query(lang, keyword, original_query)
    end)
  rescue
    e ->
      Logger.error("[WikipediaService] Erreur individuel #{lang} : #{Exception.message(e)}")
      nil
  end

  @doc "Requête l'API Wikipedia et extrait le texte."
  def wiki_query(lang, search_text, original_query \\ "", opts \\ []) do
    relaxed = Keyword.get(opts, :relaxed, false)
    search_term = URI.encode(search_text, &URI.char_unreserved?/1)
    url = "https://#{lang}.wikipedia.org/w/api.php?action=query&list=search&srsearch=#{search_term}&srlimit=5&format=json"

    case Req.get(url, receive_timeout: 10_000) do
      {:ok, %{status: 200, body: body}} ->
        results = get_in(body, ["query", "search"]) || []

        {results, _body} =
          if results == [] do
            suggestion = get_in(body, ["query", "searchinfo", "suggestion"])

            if suggestion do
              Logger.info("[WikipediaService] Suggestion : #{suggestion}")
              new_url =
                "https://#{lang}.wikipedia.org/w/api.php?action=query&list=search&srsearch=#{URI.encode(suggestion, &URI.char_unreserved?/1)}&srlimit=5&format=json"

              case Req.get(new_url, receive_timeout: 10_000) do
                {:ok, %{status: 200, body: new_body}} ->
                  {get_in(new_body, ["query", "search"]) || [], new_body}

                _ ->
                  {[], body}
              end
            else
              {[], body}
            end
          else
            {results, body}
          end

        if results == [] do
          Logger.info("[WikipediaService] Aucun résultat pour '#{search_text}'")
          nil
        else
          process_wiki_results(results, lang, search_text, original_query, relaxed)
        end

      _ ->
        nil
    end
  rescue
    e ->
      Logger.error("[WikipediaService] Erreur wiki_query : #{Exception.message(e)}")
      nil
  end

  @doc "Extrait le texte complet d'une page Wikipedia."
  def wiki_extract(lang, page_title, original_query \\ "") do
    encoded_title = URI.encode(page_title, &URI.char_unreserved?/1)
    url = "https://#{lang}.wikipedia.org/w/api.php?action=query&titles=#{encoded_title}&prop=extracts&explaintext=1&redirects=1&format=json"

    case Req.get(url, receive_timeout: 15_000) do
      {:ok, %{status: 200, body: body}} ->
        pages = get_in(body, ["query", "pages"]) || %{}
        full_text = pages |> Map.values() |> List.first(%{}) |> Map.get("extract")

        if is_nil(full_text) or String.trim(full_text) == "" do
          nil
        else
          if disambiguation_page?(full_text) do
            Logger.info("[WikipediaService] Page de désambiguïsation : #{page_title}")
            follow_disambiguation(lang, page_title, original_query, full_text)
          else
            clean_text =
              full_text
              |> String.replace(~r/Sauf indication contraire[^.]*\./, "")
              |> String.replace(~r/==\s*Voir aussi\s*==.*\z/s, "")
              |> String.replace(~r/==\s*Notes et références\s*==.*\z/s, "")
              |> String.trim()

            clean_text =
              if String.length(clean_text) < 300 do
                Logger.info(
                  "[WikipediaService] Texte court (#{String.length(clean_text)} chars), essai tableau HTML"
                )

                table_text = wiki_extract_table(lang, page_title)

                if table_text do
                  intro_line =
                    clean_text |> String.split("\n") |> List.first("") |> String.trim()

                  "#{intro_line}\n#{table_text}"
                else
                  clean_text
                end
              else
                clean_text
              end

            best_section = Chatgpt.IntentDetector.find_best_section(clean_text, original_query)

            best_section =
              if String.length(best_section) > 2000 do
                truncated = String.slice(best_section, 0, 2000)
                last_newline = truncated |> String.graphemes() |> Enum.reverse() |> Enum.find_index(&(&1 == "\n"))

                if last_newline && 2000 - last_newline > 100 do
                  String.slice(truncated, 0, 2000 - last_newline - 1)
                else
                  truncated
                end
              else
                best_section
              end

            if String.trim(best_section) == "", do: nil, else: best_section
          end
        end

      _ ->
        nil
    end
  rescue
    e ->
      Logger.error("[WikipediaService] Erreur wiki_extract '#{page_title}' : #{Exception.message(e)}")
      nil
  end

  @doc "Extrait un tableau HTML depuis une page Wikipedia."
  def wiki_extract_table(lang, page_title) do
    encoded = URI.encode(page_title, &URI.char_unreserved?/1)
    url = "https://#{lang}.wikipedia.org/w/api.php?action=parse&page=#{encoded}&prop=text&redirects=1&format=json"

    case Req.get(url, receive_timeout: 15_000) do
      {:ok, %{status: 200, body: body}} ->
        html = get_in(body, ["parse", "text", "*"])

        if is_nil(html) do
          nil
        else
          rows =
            Regex.scan(~r/<tr[^>]*>(.*?)<\/tr>/s, html)
            |> Enum.map(fn [_, tr] ->
              Regex.scan(~r/<t[dh][^>]*>(.*?)<\/t[dh]>/s, tr)
              |> Enum.map(fn [_, cell] ->
                cell
                |> String.replace(~r/<[^>]*>/, "")
                |> String.replace("&nbsp;", " ")
                |> String.replace("&#160;", " ")
                |> String.replace("&gt;", ">")
                |> String.replace("&lt;", "<")
                |> String.replace("&amp;", "&")
                |> String.replace(~r/&#91;.*?&#93;/, "")
                |> String.replace(~r/\[.*?\]/, "")
                |> String.trim()
              end)
              |> Enum.reject(&(&1 == ""))
            end)
            |> Enum.filter(fn row -> length(row) >= 2 end)

          data_rows = Enum.drop(rows, 1)

          if Enum.empty?(data_rows) do
            nil
          else
            data_rows
            |> Enum.take(15)
            |> Enum.map(fn row -> Enum.join(row, " — ") end)
            |> Enum.join("\n")
          end
        end

      _ ->
        nil
    end
  rescue
    e ->
      Logger.error("[WikipediaService] Erreur tableau '#{page_title}' : #{Exception.message(e)}")
      nil
  end

  @doc "Suit une page de désambiguïsation pour trouver le bon article."
  def follow_disambiguation(lang, page_title, original_query, disambig_text) do
    encoded = URI.encode(page_title, &URI.char_unreserved?/1)
    url = "https://#{lang}.wikipedia.org/w/api.php?action=query&titles=#{encoded}&prop=links&pllimit=30&plnamespace=0&format=json"

    case Req.get(url, receive_timeout: 10_000) do
      {:ok, %{status: 200, body: body}} ->
        pages = get_in(body, ["query", "pages"]) || %{}
        links = pages |> Map.values() |> List.first(%{}) |> Map.get("links", [])
        link_titles = Enum.map(links, fn l -> l["title"] end) |> Enum.reject(&is_nil/1)

        if Enum.empty?(link_titles) do
          nil
        else
          disambig_lines =
            disambig_text
            |> String.split("\n")
            |> Enum.map(&String.trim/1)
            |> Enum.reject(&(&1 == ""))

          query_keywords = Chatgpt.KeywordExtractor.extract(original_query)
          page_words = Chatgpt.TextNormalizer.normalize(page_title)

          discriminating =
            query_keywords
            |> Enum.reject(fn qw ->
              Enum.any?(page_words, fn pw -> Chatgpt.SimilarityCalculator.stem_match?(qw, pw) end)
            end)

          discriminating = if discriminating == [], do: query_keywords, else: discriminating

          scored =
            Enum.map(link_titles, fn title ->
              title_lower = String.downcase(title)
              title_words = Chatgpt.TextNormalizer.normalize(title)

              matching_lines =
                Enum.filter(disambig_lines, fn line ->
                  String.contains?(String.downcase(line), title_lower) or
                    Enum.all?(title_words, fn tw -> String.contains?(String.downcase(line), tw) end)
                end)

              desc_words =
                matching_lines
                |> Enum.flat_map(fn line -> Chatgpt.TextNormalizer.normalize(line) end)
                |> Enum.uniq()

              desc_match =
                Enum.count(discriminating, fn qw ->
                  Enum.any?(desc_words, fn dw -> Chatgpt.SimilarityCalculator.stem_match?(qw, dw) end)
                end)

              title_match =
                Enum.count(discriminating, fn qw ->
                  Enum.any?(title_words, fn tw -> Chatgpt.SimilarityCalculator.stem_match?(qw, tw) end)
                end)

              year_penalty = if Regex.match?(~r/\b(19|20)\d{2}\b/, title), do: 2, else: 0
              list_penalty = if String.starts_with?(String.downcase(title), "liste"), do: 2, else: 0
              score = desc_match * 3 + title_match * 2 - year_penalty - list_penalty

              %{title: title, score: score, desc_match: desc_match, title_match: title_match}
            end)

          scored =
            scored
            |> Enum.filter(fn s -> s.score > 0 end)
            |> Enum.sort_by(fn s -> {-s.score, -s.desc_match} end)

          Logger.info(
            "[WikipediaService] Désambiguïsation #{page_title} : #{scored |> Enum.take(5) |> Enum.map(fn s -> "#{s.title}(#{s.score})" end) |> Enum.join(", ")}"
          )

          scored
          |> Enum.take(3)
          |> Enum.find_value(fn s ->
            Logger.info("[WikipediaService] Essai désambiguïsation : #{s.title}")
            wiki_extract(lang, s.title, original_query)
          end)
        end

      _ ->
        nil
    end
  rescue
    e ->
      Logger.error("[WikipediaService] Erreur follow_disambiguation : #{Exception.message(e)}")
      nil
  end

  # --- Fonctions privées ---

  defp process_wiki_results(results, lang, search_text, original_query, relaxed) do
    search_words = Chatgpt.TextNormalizer.normalize(search_text)
    min_required = max(ceil(length(search_words) / 2), 1)

    matching =
      results
      |> Enum.with_index()
      |> Enum.map(fn {r, idx} ->
        title_words = Chatgpt.TextNormalizer.normalize(r["title"] || "")

        snippet_text =
          (r["snippet"] || "")
          |> String.replace(~r/<[^>]*>/, "")
          |> String.replace("&#0*39;", "'")
          |> String.replace("&amp;", "&")
          |> String.replace("&quot;", "\"")
          |> String.downcase()

        snippet_words = Chatgpt.TextNormalizer.normalize(snippet_text)
        title_match = Chatgpt.SimilarityCalculator.stem_match_count(search_words, title_words)

        unmatched =
          Enum.reject(search_words, fn sw ->
            Enum.any?(title_words, fn tw -> Chatgpt.SimilarityCalculator.stem_match?(sw, tw) end)
          end)

        snippet_bonus = Chatgpt.SimilarityCalculator.stem_match_count(unmatched, snippet_words)
        unique_matches = title_match + snippet_bonus
        weighted_score = title_match * 2 + snippet_bonus

        %{
          result: r,
          title_match: title_match,
          snippet_bonus: snippet_bonus,
          unique_matches: unique_matches,
          weighted_score: weighted_score,
          index: idx
        }
      end)
      |> Enum.filter(fn m -> m.unique_matches >= min_required end)
      |> Enum.sort_by(fn m -> {-m.weighted_score, -m.title_match, m.index} end)

    found =
      Enum.find_value(matching, fn m ->
        page_title = m.result["title"]

        Logger.info(
          "[WikipediaService] Essai : #{page_title} (weighted=#{m.weighted_score}, titre=#{m.title_match}, snippet=#{m.snippet_bonus})"
        )

        wiki_extract(lang, page_title, original_query)
      end)

    found ||
      if relaxed do
        already_tried = Enum.map(matching, fn m -> m.result["title"] end)

        results
        |> Enum.reject(fn r -> r["title"] in already_tried end)
        |> Enum.find_value(fn r ->
          title_words = Chatgpt.TextNormalizer.normalize(r["title"] || "")
          snippet = (r["snippet"] || "") |> String.replace(~r/<[^>]*>/, "") |> String.downcase()

          found_words =
            Enum.filter(search_words, fn w ->
              w in title_words or String.contains?(snippet, w)
            end)

          if length(found_words) >= min_required do
            Logger.info("[WikipediaService] Essai relaxé : #{r["title"]}")
            wiki_extract(lang, r["title"], original_query)
          end
        end)
      end
  end

  defp search_country_related(query, query_words, keywords, indicators) do
    has_power_word =
      Enum.any?(query_words, fn qw ->
        Enum.any?(~w(puissant puissants puissantes puissance puissances), fn w ->
          Chatgpt.SimilarityCalculator.stem_match?(qw, w)
        end)
      end)

    if has_power_word do
      power_keywords = ["grande", "puissance", "pays"]
      Logger.info("[WikipediaService] Grandes puissances : #{Enum.join(power_keywords, " ")}")
      extract = wiki_search("fr", power_keywords, query)
      if extract, do: Chatgpt.SearchResult.from_wikipedia(extract) |> Chatgpt.SearchResult.format()
    else
      topic_only =
        Enum.reject(keywords, fn k ->
          Enum.any?(indicators, fn w -> Chatgpt.SimilarityCalculator.stem_match?(k, w) end)
        end)

      result =
        if topic_only != [] and topic_only != keywords do
          core_topic =
            Enum.reject(topic_only, fn w ->
              Regex.match?(~r/\A[a-zà-ÿ]+(ent|ons|ez|aient|ront|raient)\z/u, w)
            end)

          core_topic = if core_topic == [], do: topic_only, else: core_topic

          Logger.info("[WikipediaService] Topic principal : #{Enum.join(core_topic, " ")}")
          extract = wiki_search("fr", core_topic, query)

          if extract do
            Chatgpt.SearchResult.from_wikipedia(extract) |> Chatgpt.SearchResult.format()
          else
            if core_topic != topic_only do
              Logger.info("[WikipediaService] Topic complet : #{Enum.join(topic_only, " ")}")
              extract2 = wiki_search("fr", topic_only, query)
              if extract2, do: Chatgpt.SearchResult.from_wikipedia(extract2) |> Chatgpt.SearchResult.format()
            end
          end
        end

      result ||
        (fn ->
          specific_keywords = ["liste"] ++ keywords
          Logger.info("[WikipediaService] Spécifique pays : #{Enum.join(specific_keywords, " ")}")
          extract = wiki_search("fr", specific_keywords, query)
          if extract, do: Chatgpt.SearchResult.from_wikipedia(extract) |> Chatgpt.SearchResult.format()
        end).()
    end
  end

  defp wiki_search(lang, keywords, original_query) do
    wiki_query(lang, Enum.join(keywords, " "), original_query)
  rescue
    e ->
      Logger.error("[WikipediaService] Erreur wiki_search #{lang} : #{Exception.message(e)}")
      nil
  end

  defp disambiguation_page?(text) do
    String.contains?(text, "peut faire référence") or
      String.contains?(text, "peut désigner") or
      String.contains?(text, "Cette page d'homonymie") or
      String.contains?(text, "page d'homonymie") or
      Regex.match?(~r/\A[^\n]{0,50}\s+peut\s+(faire référence|désigner|se référer)/, text)
  end

  defp get_country_indicators do
    indicators = Chatgpt.IntentDetector.country_indicators()
    if indicators == [], do: ~w(pays état nation puissance puissant), else: indicators
  end

  defp cast_query?(query_words) do
    intent_words = Chatgpt.IntentDetector.intent_words()
    cast_words = Map.get(intent_words, :cast, [])

    cast_words != [] and
      Enum.any?(cast_words, fn w ->
        Enum.any?(query_words, fn qw -> Chatgpt.SimilarityCalculator.stem_match?(qw, w) end)
      end)
  end
end
