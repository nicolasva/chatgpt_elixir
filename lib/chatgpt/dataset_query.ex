defmodule Chatgpt.DatasetQuery do
  @moduledoc """
  Encapsule la logique de recherche dans le dataset en mémoire.
  Supporte la correspondance exacte (normalisée) et la similarité Jaccard.
  """

  @similarity_threshold 0.5

  @doc "Retourne le meilleur match (exact ou par similarité). Accepte une liste de docs en option (utile pour les tests)."
  def find_best_match(user_message, docs \\ nil) do
    docs = docs || Chatgpt.AutoLearner.get_docs()
    find_exact_match(user_message, docs) || find_similarity_match(user_message, docs)
  end

  defp find_exact_match(user_message, docs) do
    user_words = Chatgpt.TextNormalizer.normalize(user_message)

    docs
    |> Enum.filter(fn d ->
      Map.get(d, "question") &&
        Chatgpt.TextNormalizer.normalize(Map.get(d, "question", "")) == user_words
    end)
    |> case do
      [] -> nil
      matches -> Enum.random(matches)
    end
  end

  defp find_similarity_match(user_message, docs) do
    user_words_filtered = Chatgpt.SimilarityCalculator.normalize_for_matching(user_message)

    {best_doc, best_score} =
      Enum.reduce(docs, {nil, 0.0}, fn d, {best, score} ->
        if Map.get(d, "question") do
          s =
            Chatgpt.SimilarityCalculator.jaccard(
              user_words_filtered,
              Chatgpt.SimilarityCalculator.normalize_for_matching(Map.get(d, "question", ""))
            )

          if s > score, do: {d, s}, else: {best, score}
        else
          {best, score}
        end
      end)

    if best_score > @similarity_threshold, do: best_doc, else: nil
  end
end
