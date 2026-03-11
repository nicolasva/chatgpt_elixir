defmodule Chatgpt.WiktionaryService do
  @moduledoc """
  Client pour le Wiktionnaire français : synonymes, définitions, correction orthographique.
  """

  require Logger

  @base_url "https://fr.wiktionary.org/w/api.php"

  @doc "Trouve les synonymes d'un mot via le Wiktionnaire."
  def find_synonyms(word) do
    encoded = URI.encode(String.downcase(word), &URI.char_unreserved?/1)
    url = "#{@base_url}?action=parse&page=#{encoded}&prop=wikitext&format=json"

    case Req.get(url, receive_timeout: 10_000) do
      {:ok, %{status: 200, body: body}} ->
        wikitext = get_in(body, ["parse", "wikitext", "*"])
        if wikitext, do: extract_synonyms(wikitext), else: []

      _ ->
        []
    end
  rescue
    e ->
      Logger.error("[WiktionaryService] Erreur synonymes '#{word}' : #{Exception.message(e)}")
      []
  end

  @doc "Récupère la définition d'un mot."
  def definition(word) do
    encoded = URI.encode(String.downcase(word), &URI.char_unreserved?/1)
    url = "#{@base_url}?action=parse&page=#{encoded}&prop=wikitext&format=json"

    case Req.get(url, receive_timeout: 10_000) do
      {:ok, %{status: 200, body: body}} ->
        wikitext = get_in(body, ["parse", "wikitext", "*"])
        if wikitext, do: extract_definition(wikitext), else: nil

      _ ->
        nil
    end
  rescue
    e ->
      Logger.error("[WiktionaryService] Erreur définition '#{word}' : #{Exception.message(e)}")
      nil
  end

  @doc "Suggère une correction orthographique via le Wiktionnaire."
  def correct_spelling(word) do
    encoded = URI.encode(String.downcase(word), &URI.char_unreserved?/1)
    url = "#{@base_url}?action=query&list=search&srsearch=#{encoded}&srlimit=1&format=json"

    case Req.get(url, receive_timeout: 10_000) do
      {:ok, %{status: 200, body: body}} ->
        suggestion = get_in(body, ["query", "searchinfo", "suggestion"])

        if suggestion && suggestion != String.downcase(word) do
          suggestion
        else
          results = get_in(body, ["query", "search"]) || []

          case results do
            [%{"title" => title} | _] ->
              lower_title = String.downcase(title)

              if lower_title != String.downcase(word) &&
                   Chatgpt.SimilarityCalculator.levenshtein_close?(
                     String.downcase(word),
                     lower_title
                   ) do
                lower_title
              else
                nil
              end

            _ ->
              nil
          end
        end

      _ ->
        nil
    end
  rescue
    e ->
      Logger.error(
        "[WiktionaryService] Erreur correction '#{word}' : #{Exception.message(e)}"
      )

      nil
  end

  defp extract_synonyms(wikitext) do
    lines = String.split(wikitext, "\n")

    {synonyms, _in_syn} =
      Enum.reduce(lines, {[], false}, fn line, {acc, in_synonyms} ->
        cond do
          String.contains?(line, "{{S|synonymes") ->
            {acc, true}

          in_synonyms && Regex.match?(~r/\{\{S\|/, line) ->
            {acc, false}

          in_synonyms ->
            case Regex.run(~r/\[\[([^\]|#]+)/, line) do
              [_, match] ->
                word = String.trim(String.downcase(match))
                if word != "", do: {[word | acc], true}, else: {acc, true}

              _ ->
                {acc, true}
            end

          true ->
            {acc, in_synonyms}
        end
      end)

    synonyms |> Enum.reverse() |> Enum.take(5)
  end

  defp extract_definition(wikitext) do
    wikitext
    |> String.split("\n")
    |> Enum.find_value(fn line ->
      if Regex.match?(~r/\A#[^#*:]/, line) do
        clean =
          line
          |> String.replace(~r/\A#+\s*/, "")
          |> String.replace(~r/\{\{[^}]*\}\}/, "")
          |> String.replace(~r/\[\[(?:[^|\]]*\|)?([^\]]*)\]\]/, "\\1")
          |> String.replace(~r/'{2,}/, "")
          |> String.trim()

        if clean != "", do: clean, else: nil
      end
    end)
  end
end
