defmodule Chatgpt.SimilarityCalculator do
  @moduledoc """
  Calcul de similarité entre textes : Jaccard, stem matching, Levenshtein.
  """

  @matching_stop_words ~w(
    je tu il elle on nous vous ils elles
    le la les l un une des de du au aux en
    a à est es et ou où ni ne pas
    me te se ce ça sa son ses mon ma mes ton ta tes
    qui que quoi dont quel quelle quels quelles
    film films acteur acteurs actrice actrices
    connais sais dire dis peux peut faire fait
    sont pour par sur dans avec sans vers chez entre contre
    comment pourquoi quand combien
    être avoir etre fait font va vont sera serait
    faut falloir prendre donner utiliser
    aussi très bien plus moins tout tous toute toutes
    cette cet ces autre autres encore même
    médicament médicaments traitement traitements remède remèdes
    soigner guérir prendre soulager traiter
  )

  @doc "Normalise un texte en supprimant les mots de matching."
  def normalize_for_matching(text) do
    text
    |> Chatgpt.TextNormalizer.normalize()
    |> Enum.reject(fn w -> w in @matching_stop_words or String.length(w) < 2 end)
  end

  @doc "Calcule le coefficient de similarité Jaccard entre deux listes de mots."
  def jaccard(words_a, words_b) do
    if Enum.empty?(words_a) or Enum.empty?(words_b) do
      0.0
    else
      set_a = MapSet.new(words_a)
      set_b = MapSet.new(words_b)
      intersection = MapSet.intersection(set_a, set_b) |> MapSet.size()
      union = MapSet.union(set_a, set_b) |> MapSet.size()
      if union == 0, do: 0.0, else: intersection / union
    end
  end

  @doc "Vérifie si deux mots ont la même racine (stemming français)."
  def stem_match?(word_a, word_b) do
    if word_a == word_b do
      true
    else
      a = Chatgpt.TextNormalizer.strip_accents(word_a)
      b = Chatgpt.TextNormalizer.strip_accents(word_b)

      cond do
        a == b ->
          true

        a <> "s" == b or b <> "s" == a ->
          true

        a <> "es" == b or b <> "es" == a ->
          true

        a <> "x" == b or b <> "x" == a ->
          true

        String.replace(a, ~r/aux$/, "al") == b or String.replace(b, ~r/aux$/, "al") == a ->
          true

        true ->
          a_stem = String.replace(a, ~r/(er|ee?s?|ant|ent)$/, "")
          b_stem = String.replace(b, ~r/(er|ee?s?|ant|ent)$/, "")
          a_stem == b_stem and String.length(a_stem) >= 3
      end
    end
  end

  @doc "Compte le nombre de mots de search_words qui ont un stem correspondant dans title_words."
  def stem_match_count(search_words, title_words) do
    Enum.count(search_words, fn sw ->
      Enum.any?(title_words, fn tw -> stem_match?(sw, tw) end)
    end)
  end

  @doc "Vérifie si deux mots sont proches selon la distance de Levenshtein (>70% de similarité)."
  def levenshtein_close?(a, b) do
    if a == b do
      true
    else
      diff = abs(String.length(a) - String.length(b))

      if diff > 2 do
        false
      else
        max_len = max(String.length(a), String.length(b))
        min_len = min(String.length(a), String.length(b))
        a_chars = String.graphemes(a)
        b_chars = String.graphemes(b)

        common =
          Enum.count(0..(min_len - 1), fn i ->
            Enum.at(a_chars, i) == Enum.at(b_chars, i)
          end)

        common / max_len > 0.7
      end
    end
  end
end
