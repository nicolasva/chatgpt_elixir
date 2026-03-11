defmodule Chatgpt.IntentDetector do
  @moduledoc """
  GenServer qui détecte l'intention de l'utilisateur à partir de mots-clés.
  Charge les mots-clés depuis config/intent_keywords.yml et les enrichit via Wiktionnaire.
  """

  use GenServer
  require Logger

  @keywords_path "config/intent_keywords.yml"
  @intent_priority [:cast, :treatment, :cause, :history, :synopsis, :country]

  # --- API publique ---

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def detect(query_words) do
    GenServer.call(__MODULE__, {:detect, query_words})
  end

  def find_best_section(full_text, query) do
    GenServer.call(__MODULE__, {:find_best_section, full_text, query})
  end

  def country_indicators do
    GenServer.call(__MODULE__, :country_indicators)
  end

  def intent_words do
    GenServer.call(__MODULE__, :intent_words)
  end

  # --- Callbacks GenServer ---

  @impl true
  def init(:ok) do
    state = load_base_keywords()
    {:ok, state, {:continue, :enrich_keywords}}
  end

  @impl true
  def handle_continue(:enrich_keywords, state) do
    enriched = enrich_with_wiktionary(state)
    {:noreply, enriched}
  end

  @impl true
  def handle_call({:detect, query_words}, _from, state) do
    result =
      Enum.find(@intent_priority, fn intent ->
        words = Map.get(state.intent_words, intent, [])
        words != [] and
          Enum.any?(query_words, fn qw ->
            Enum.any?(words, fn w -> Chatgpt.SimilarityCalculator.stem_match?(qw, w) end)
          end)
      end)

    {:reply, result, state}
  end

  @impl true
  def handle_call({:find_best_section, full_text, query}, _from, state) do
    result = do_find_best_section(full_text, query, state)
    {:reply, result, state}
  end

  @impl true
  def handle_call(:country_indicators, _from, state) do
    {:reply, state.country_indicators, state}
  end

  @impl true
  def handle_call(:intent_words, _from, state) do
    {:reply, state.intent_words, state}
  end

  # --- Logique interne ---

  defp load_base_keywords do
    path = @keywords_path

    config =
      if File.exists?(path) do
        YamlElixir.read_from_file!(path)
      else
        %{}
      end

    intents = Map.get(config, "intents", %{})

    intent_words =
      Enum.reduce(intents, %{}, fn {name, data}, acc ->
        key = String.to_atom(name)
        seeds = Map.get(data, "seeds", [])
        extra = Map.get(data, "extra_words", [])
        words = (seeds ++ extra) |> Enum.map(&String.downcase/1) |> Enum.uniq()
        Map.put(acc, key, words)
      end)

    intent_targets =
      Enum.reduce(intents, %{}, fn {name, data}, acc ->
        key = String.to_atom(name)
        targets = Map.get(data, "target_sections", []) |> Enum.map(&String.downcase/1)
        Map.put(acc, key, targets)
      end)

    country_indicators =
      Map.get(config, "country_indicators", []) |> Enum.map(&String.downcase/1)

    %{
      intent_words: intent_words,
      intent_targets: intent_targets,
      country_indicators: country_indicators
    }
  rescue
    e ->
      Logger.error("[IntentDetector] Erreur chargement : #{Exception.message(e)}")
      %{intent_words: %{}, intent_targets: %{}, country_indicators: []}
  end

  defp enrich_with_wiktionary(state) do
    enriched_words =
      Enum.reduce(state.intent_words, %{}, fn {intent, words}, acc ->
        synonyms =
          words
          |> Enum.take(4)
          |> Enum.flat_map(fn seed ->
            syns = Chatgpt.WiktionaryService.find_synonyms(seed)
            if syns != [], do: Logger.info("[IntentDetector] '#{seed}' : +#{length(syns)} synonymes")
            syns
          end)

        enriched = (words ++ synonyms) |> Enum.map(&String.downcase/1) |> Enum.uniq()
        Map.put(acc, intent, enriched)
      end)

    Logger.info(
      "[IntentDetector] Enrichi (#{enriched_words |> Map.values() |> Enum.map(&length/1) |> Enum.sum()} mots)"
    )

    %{state | intent_words: enriched_words}
  rescue
    e ->
      Logger.error("[IntentDetector] Erreur enrichissement : #{Exception.message(e)}")
      state
  end

  defp do_find_best_section(full_text, query, state) do
    if query == "" do
      full_text |> String.split(~r/\n\n+==/) |> List.first() |> String.trim()
    else
      sections = parse_sections(full_text)
      intro = List.first(sections, "") |> String.trim()

      if length(sections) <= 1 do
        intro
      else
        query_words = Chatgpt.TextNormalizer.normalize(query)
        intent = detect_intent(query_words, state)
        target_keywords = if intent, do: Map.get(state.intent_targets, intent, []), else: []

        if target_keywords != [] do
          # 1er passage : titres de section
          result =
            Enum.find_value(sections, fn section ->
              first_line =
                section
                |> String.split("\n")
                |> List.first("")
                |> String.downcase()
                |> Chatgpt.TextNormalizer.strip_accents()

              if Enum.any?(target_keywords, fn kw ->
                   String.contains?(
                     first_line,
                     Chatgpt.TextNormalizer.strip_accents(kw)
                   )
                 end) do
                content =
                  section
                  |> String.split("\n")
                  |> Enum.reject(fn l -> Regex.match?(~r/\A={2,3}\s/, l) end)
                  |> Enum.join("\n")
                  |> String.trim()

                if content != "", do: content, else: nil
              end
            end)

          # 2ème passage : sous-sections
          result =
            result ||
              Enum.find_value(sections, fn section ->
                lines = String.split(section, "\n")

                combined =
                  lines
                  |> Enum.with_index()
                  |> Enum.flat_map(fn {line, idx} ->
                    if Regex.match?(~r/\A===/, line) do
                      line_lower =
                        String.downcase(line) |> Chatgpt.TextNormalizer.strip_accents()

                      if Enum.any?(target_keywords, fn kw ->
                           String.contains?(
                             line_lower,
                             Chatgpt.TextNormalizer.strip_accents(kw)
                           )
                         end) do
                        lines
                        |> Enum.drop(idx + 1)
                        |> Enum.take_while(fn l -> not Regex.match?(~r/\A={2,3}\s/, l) end)
                      else
                        []
                      end
                    else
                      []
                    end
                  end)

                content = Enum.join(combined, "\n") |> String.trim()
                if content != "", do: content, else: nil
              end)

          result || intro
        else
          intro
        end
      end
    end
  end

  defp detect_intent(query_words, state) do
    Enum.find(@intent_priority, fn intent ->
      words = Map.get(state.intent_words, intent, [])
      words != [] and
        Enum.any?(query_words, fn qw ->
          Enum.any?(words, fn w -> Chatgpt.SimilarityCalculator.stem_match?(qw, w) end)
        end)
    end)
  end

  defp parse_sections(full_text) do
    {sections, current} =
      full_text
      |> String.split("\n")
      |> Enum.reduce({[], ""}, fn line, {sections, current} ->
        if Regex.match?(~r/\A==\s[^=]/, line) and current != "" do
          {[String.trim(current) | sections], line <> "\n"}
        else
          {sections, current <> line <> "\n"}
        end
      end)

    all = if String.trim(current) != "", do: [String.trim(current) | sections], else: sections
    Enum.reverse(all)
  end
end
