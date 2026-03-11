defmodule Chatgpt.CompoundPhraseResolver do
  @moduledoc """
  GenServer qui résout les expressions composées françaises (médicales/santé)
  via le Wiktionnaire. Utilise un cache ETS.
  """

  use GenServer
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
      ~r/\b(brûlures?\s+d\s*['']\s*estomac)/iu
    ]
  end

  # --- API publique ---

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def resolve(text) do
    GenServer.call(__MODULE__, {:resolve, text}, 30_000)
  end

  # --- Callbacks GenServer ---

  @impl true
  def init(:ok) do
    Logger.info("[CompoundPhraseResolver] Démarré avec cache vide.")
    {:ok, %{cache: %{}}}
  end

  @impl true
  def handle_call({:resolve, text}, _from, state) do
    {result, new_state} = do_resolve(String.downcase(text), state)
    {:reply, result, new_state}
  end

  # --- Logique interne ---

  defp do_resolve(text, state) do
    Enum.reduce(compound_patterns(), {text, state}, fn pattern, {current_text, current_state} ->
      {new_text, new_state} =
        resolve_pattern(current_text, pattern, current_state)

      {new_text, new_state}
    end)
  end

  defp resolve_pattern(text, pattern, state) do
    matches = Regex.scan(pattern, text) |> Enum.map(fn [_, match] -> match end) |> Enum.uniq()

    Enum.reduce(matches, {text, state}, fn match, {current_text, current_state} ->
      phrase = String.trim(String.downcase(match))
      {replacement, new_state} = get_replacement(phrase, current_state)
      new_text = String.replace(current_text, match, replacement)
      {new_text, new_state}
    end)
  end

  defp get_replacement(phrase, state) do
    if Map.has_key?(state.cache, phrase) do
      {state.cache[phrase], state}
    else
      synonyms = Chatgpt.WiktionaryService.find_synonyms(phrase)

      if synonyms != [] do
        replacement = List.first(synonyms)
        Logger.info("[CompoundPhraseResolver] '#{phrase}' → '#{replacement}' (synonyme)")
        new_cache = Map.put(state.cache, phrase, replacement)
        {replacement, %{state | cache: new_cache}}
      else
        definition = Chatgpt.WiktionaryService.definition(phrase)

        if definition do
          def_keywords = Chatgpt.KeywordExtractor.extract(definition) |> Enum.take(1)

          if def_keywords != [] do
            replacement = List.first(def_keywords)
            Logger.info("[CompoundPhraseResolver] '#{phrase}' → '#{replacement}' (définition)")
            new_cache = Map.put(state.cache, phrase, replacement)
            {replacement, %{state | cache: new_cache}}
          else
            Logger.info("[CompoundPhraseResolver] Expression non résolue : '#{phrase}'")
            new_cache = Map.put(state.cache, phrase, phrase)
            {phrase, %{state | cache: new_cache}}
          end
        else
          Logger.info("[CompoundPhraseResolver] Expression non résolue : '#{phrase}'")
          new_cache = Map.put(state.cache, phrase, phrase)
          {phrase, %{state | cache: new_cache}}
        end
      end
    end
  rescue
    e ->
      Logger.error("[CompoundPhraseResolver] Erreur '#{phrase}' : #{Exception.message(e)}")
      {phrase, state}
  end
end
