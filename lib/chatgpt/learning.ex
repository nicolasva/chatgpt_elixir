defmodule Chatgpt.Learning do
  @moduledoc """
  Context d'apprentissage.
  Regroupe la gestion du dataset et l'auto-apprentissage.
  """

  alias Chatgpt.{AutoLearner, Dataset, DatasetQuery}

  @doc "Retourne tous les documents en mémoire."
  defdelegate get_docs(), to: AutoLearner

  @doc "Ajoute un document en mémoire."
  defdelegate add_doc(doc), to: AutoLearner

  @doc "Apprend les questions en attente pour une session."
  defdelegate learn_pending(session_id, answer), to: AutoLearner

  @doc "Gère une réponse de fallback (apprentissage depuis le web)."
  defdelegate handle_fallback(session_id, msg, answer), to: AutoLearner

  @doc "Trouve la meilleure correspondance dans le dataset."
  defdelegate find_best_match(message), to: DatasetQuery

  @doc "Trouve la meilleure correspondance avec un dataset fourni."
  defdelegate find_best_match(message, docs), to: DatasetQuery

  @doc "Retourne toutes les entrées du dataset."
  defdelegate all_entries(), to: Dataset, as: :all

  @doc "Crée une nouvelle entrée dans le dataset."
  defdelegate create_entry(attrs), to: Dataset, as: :create
end
