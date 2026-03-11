defmodule Chatgpt.CompoundPhraseResolver do
  @moduledoc """
  Agent qui résout les expressions composées françaises (médicales/santé)
  via le Wiktionnaire. Utilise un cache en mémoire (map).
  """

  use Agent
  require Logger

  defp compound_patterns do
    [
      ~r/\b(maux?\s+(?:de|du|des|au|aux|à\s+la|à\s+l)\s+\w+)/iu,
      ~r/\b(coup\s+de\s+\w+)/iu,
      ~r/\b(rhume\s+des?\s+\w+)/iu,
      ~r/\b(crise\s+\w+)/iu,
      ~r/\b(arrêt\s+\w+)/iu,
      ~r/\b(tension\s+\w+)/iu,
      ~r/\b(pression\s+\w+)/iu,
      ~r/\b(nez\s+(?:bouché|qui\s+coule))/iu,
      ~r/\b(brûlures?\s+d\s*['']?\s*estomac)/iu
    ]
  end

  # --- API publique ---

  def start_link(_opts) do
    Agent.start_link(fn ->
      Logger.info("[CompoundPhraseResolver] Démarré avec cache vide.")
      %{}
    end, name: __MODULE__)
  end

  def resolve(text) do
    Enum.reduce(compound_patterns(), String.downcase(text), fn pattern, current_text ->
      resolve_pattern(current_text, pattern)
    end)
  end

  # --- Logique interne ---

  defp resolve_pattern(text, pattern) do
    matches = Regex.scan(pattern, text) |> Enum.map(fn [_, match] -> match end) |> Enum.uniq()

    Enum.reduce(matches, text, fn match, current_text ->
      phrase = String.trim(String.downcase(match))
      replacement = get_replacement(phrase)
      String.replace(current_text, match, replacement)
    end)
  end

  defp get_replacement(phrase) do
    case Agent.get(__MODULE__, &Map.get(&1, phrase, :miss)) do
      :miss ->
        replacement = fetch_replacement(phrase)
        Agent.update(__MODULE__, &Map.put(&1, phrase, replacement))
        replacement

      cached ->
        cached
    end
  end

  defp fetch_replacement(phrase) do
    synonyms = Chatgpt.WiktionaryService.find_synonyms(phrase)

    if synonyms != [] do
      replacement = List.first(synonyms)
      Logger.info("[CompoundPhraseResolver] '#{phrase}' → '#{replacement}' (synonyme)")
      replacement
    else
      definition = Chatgpt.WiktionaryService.definition(phrase)

      if definition do
        def_keywords = Chatgpt.KeywordExtractor.extract(definition) |> Enum.take(1)

        if def_keywords != [] do
          replacement = List.first(def_keywords)
          Logger.info("[CompoundPhraseResolver] '#{phrase}' → '#{replacement}' (définition)")
          replacement
        else
          Logger.info("[CompoundPhraseResolver] Expression non résolue : '#{phrase}'")
          phrase
        end
      else
        Logger.info("[CompoundPhraseResolver] Expression non résolue : '#{phrase}'")
        phrase
      end
    end
  rescue
    e ->
      Logger.error("[CompoundPhraseResolver] Erreur '#{phrase}' : #{Exception.message(e)}")
      phrase
  end
end
