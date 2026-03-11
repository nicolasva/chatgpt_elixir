defmodule Chatgpt.AutoLearner do
  @moduledoc """
  GenServer gérant l'apprentissage automatique :
  - pending_learns : questions sans réponse mises en attente
  - handle_fallback : sauvegarde la réponse web si pertinente
  Maintient aussi la liste in-memory du dataset.
  """

  use GenServer
  require Logger

  @web_prefixes Chatgpt.SearchResult.web_sources()

  # --- API publique ---

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def get_docs do
    GenServer.call(__MODULE__, :get_docs)
  end

  def add_doc(doc) do
    GenServer.cast(__MODULE__, {:add_doc, doc})
  end

  def learn_pending(session_id, answer) do
    GenServer.call(__MODULE__, {:learn_pending, session_id, answer})
  end

  def handle_fallback(session_id, msg, answer) do
    GenServer.call(__MODULE__, {:handle_fallback, session_id, msg, answer})
  end

  # --- Callbacks GenServer ---

  @impl true
  def init(:ok) do
    Logger.info("[AutoLearner] Chargement du dataset depuis CouchDB...")
    Chatgpt.Memory.ensure_views!()
    docs = load_and_clean_docs()
    Logger.info("[AutoLearner] #{length(docs)} entrées chargées.")
    {:ok, %{docs: docs, pending: %{}}}
  end

  @impl true
  def handle_call(:get_docs, _from, state) do
    {:reply, state.docs, state}
  end

  @impl true
  def handle_call({:learn_pending, session_id, answer}, _from, state) do
    {pending_msgs, new_pending} = Map.pop(state.pending, session_id, [])

    new_docs =
      Enum.reduce(pending_msgs, state.docs, fn msg, docs ->
        normalized = Chatgpt.TextNormalizer.normalize(msg)

        if normalized == [] or already_known?(msg, docs) do
          docs
        else
          pair = %{"question" => String.downcase(String.trim(msg)), "answer" => answer}

          case Chatgpt.Dataset.create(pair) do
            {:ok, _} ->
              Logger.info("[AutoLearner] Appris : '#{pair["question"]}' => '#{answer}'")
              [pair | docs]

            _ ->
              docs
          end
        end
      end)

    {:reply, :ok, %{state | docs: new_docs, pending: new_pending}}
  end

  @impl true
  def handle_call({:handle_fallback, session_id, msg, answer}, _from, state) do
    msg = ensure_user_message(msg, session_id)

    new_state =
      if web_answer?(answer) do
        save_web_answer_if_relevant(session_id, msg, answer, state)
      else
        if not String.starts_with?(answer, "Météo à") do
          new_pending =
            Map.update(state.pending, session_id, [msg.raw], fn msgs -> [msg.raw | msgs] end)

          %{state | pending: new_pending}
        else
          state
        end
      end

    {:reply, :ok, new_state}
  end

  @impl true
  def handle_cast({:add_doc, doc}, state) do
    {:noreply, %{state | docs: [doc | state.docs]}}
  end

  # --- Logique interne ---

  defp load_and_clean_docs do
    all_docs = Chatgpt.Dataset.seed_if_empty!()

    # Nettoie les réponses provenant du web (comme DatasetCleanerService en Ruby)
    Enum.reject(all_docs, fn d ->
      answer = Map.get(d, "answer", "")
      Enum.any?(@web_prefixes, fn prefix -> String.starts_with?(answer, "D'après #{prefix}") end) or
        String.starts_with?(answer, "Résultats ")
    end)
  end

  defp save_web_answer_if_relevant(session_id, msg, answer, state) do
    normalized_q = String.downcase(String.trim(msg.raw))

    if already_saved?(normalized_q, state.docs) do
      state
    else
      resolved = Chatgpt.CompoundPhraseResolver.resolve(msg.raw)
      question_keywords = Chatgpt.KeywordExtractor.extract(resolved)
      relevant = Enum.any?(question_keywords, fn kw -> String.contains?(String.downcase(answer), kw) end)

      if relevant do
        pair = %{"question" => normalized_q, "answer" => answer}

        case Chatgpt.Dataset.create(pair) do
          {:ok, _} ->
            Logger.info("[AutoLearner] Appris depuis le web : '#{normalized_q}'")
            %{state | docs: [pair | state.docs]}

          _ ->
            state
        end
      else
        Logger.info("[AutoLearner] Réponse web non pertinente, mise en attente : '#{normalized_q}'")

        new_pending =
          Map.update(state.pending, session_id, [msg.raw], fn msgs -> [msg.raw | msgs] end)

        %{state | pending: new_pending}
      end
    end
  end

  defp already_known?(msg, docs) do
    normalized = Chatgpt.TextNormalizer.normalize(msg)

    Enum.any?(docs, fn d ->
      Map.get(d, "question") &&
        Chatgpt.TextNormalizer.normalize(Map.get(d, "question", "")) == normalized
    end)
  end

  defp already_saved?(normalized_q, docs) do
    Enum.any?(docs, fn d -> Map.get(d, "question") == normalized_q end)
  end

  defp web_answer?(nil), do: false

  defp web_answer?(answer) do
    Enum.any?(@web_prefixes, fn src ->
      String.contains?(answer, src) and String.length(answer) > String.length(src) + 20
    end)
  end

  defp ensure_user_message(%Chatgpt.UserMessage{} = msg, _session_id), do: msg

  defp ensure_user_message(raw, session_id) do
    Chatgpt.UserMessage.new(to_string(raw), session_id)
  end
end
