defmodule Chatgpt.Analysis do
  @moduledoc """
  Context d'analyse de texte.
  Regroupe la détection d'intention, la résolution d'expressions composées et le NLP.
  """

  alias Chatgpt.{IntentDetector, CompoundPhraseResolver, KeywordExtractor, TextNormalizer, SimilarityCalculator}

  @doc "Détecte l'intention à partir d'une liste de mots."
  defdelegate detect_intent(query_words), to: IntentDetector, as: :detect

  @doc "Résout les expressions composées françaises."
  defdelegate resolve_phrases(text), to: CompoundPhraseResolver, as: :resolve

  @doc "Trouve la meilleure section Wikipedia correspondant à une requête."
  defdelegate find_best_section(full_text, query), to: IntentDetector

  @doc "Retourne les indicateurs de pays."
  defdelegate country_indicators(), to: IntentDetector

  @doc "Extrait les mots-clés significatifs d'un texte."
  defdelegate extract_keywords(text), to: KeywordExtractor, as: :extract

  @doc "Normalise un texte (minuscules, sans accents, tokenisé)."
  defdelegate normalize(text), to: TextNormalizer

  @doc "Calcule la similarité Jaccard entre deux ensembles de mots."
  defdelegate similarity(words_a, words_b), to: SimilarityCalculator, as: :jaccard
end
