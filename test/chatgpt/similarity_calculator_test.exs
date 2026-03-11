defmodule Chatgpt.SimilarityCalculatorTest do
  use ExUnit.Case, async: true

  alias Chatgpt.SimilarityCalculator

  describe "stem_match?/2" do
    test "matche les mots identiques" do
      assert SimilarityCalculator.stem_match?("chat", "chat") == true
    end

    test "matche indépendamment des accents" do
      assert SimilarityCalculator.stem_match?("éléphant", "elephant") == true
    end

    test "matche le pluriel en -s" do
      assert SimilarityCalculator.stem_match?("chat", "chats") == true
    end

    test "matche le pluriel en -es" do
      assert SimilarityCalculator.stem_match?("maison", "maisons") == true
    end

    test "matche le pluriel en -x" do
      assert SimilarityCalculator.stem_match?("château", "châteaux") == true
    end

    test "matche -aux / -al (national/nationaux)" do
      assert SimilarityCalculator.stem_match?("national", "nationaux") == true
    end

    test "matche les terminaisons verbales joué/jouer" do
      assert SimilarityCalculator.stem_match?("joué", "jouer") == true
    end

    test "matche les terminaisons verbales joué/joue" do
      assert SimilarityCalculator.stem_match?("joué", "joue") == true
    end

    test "matche les terminaisons verbales jouée/jouer" do
      assert SimilarityCalculator.stem_match?("jouée", "jouer") == true
    end

    test "matche visiter/visité" do
      assert SimilarityCalculator.stem_match?("visiter", "visité") == true
    end

    test "ne matche pas les mots complètement différents" do
      assert SimilarityCalculator.stem_match?("chat", "chien") == false
    end

    test "ne matche pas les stems trop courts" do
      assert SimilarityCalculator.stem_match?("as", "ant") == false
    end

    test "matche continent/continents" do
      assert SimilarityCalculator.stem_match?("continent", "continents") == true
    end
  end

  describe "jaccard/2" do
    test "retourne 1.0 pour des tableaux identiques" do
      assert SimilarityCalculator.jaccard(~w[a b c], ~w[a b c]) == 1.0
    end

    test "retourne 0.0 pour des tableaux disjoints" do
      assert SimilarityCalculator.jaccard(~w[a b], ~w[c d]) == 0.0
    end

    test "retourne 0.0 pour un tableau vide" do
      assert SimilarityCalculator.jaccard([], ~w[a b]) == 0.0
    end

    test "retourne 0.0 pour deux tableaux vides" do
      assert SimilarityCalculator.jaccard([], []) == 0.0
    end

    test "calcule correctement pour un cas réel" do
      words_a = ~w[salut comment ca va]
      words_b = ~w[bonjour comment ca va]
      # intersection = {comment, ca, va} = 3, union = {salut, bonjour, comment, ca, va} = 5
      assert SimilarityCalculator.jaccard(words_a, words_b) == 0.6
    end

    test "retourne environ 0.333 pour une intersection d'un tiers" do
      # {a,b,c,d} & {a,b,e,f} => intersection=2, union=6 => 2/6 = 0.333
      result = SimilarityCalculator.jaccard(~w[a b c d], ~w[a b e f])
      assert_in_delta result, 0.333, 0.01
    end
  end

  describe "normalize_for_matching/1" do
    test "filtre les stop words du matching" do
      result = SimilarityCalculator.normalize_for_matching("je suis un développeur")
      refute "je" in result
      refute "un" in result
      assert "développeur" in result
    end

    test "filtre les mots courts" do
      result = SimilarityCalculator.normalize_for_matching("a b cd efg")
      refute "a" in result
      refute "b" in result
    end

    test "garde les mots significatifs d'une question" do
      result = SimilarityCalculator.normalize_for_matching("quel est le sens de la vie")
      assert "sens" in result
      assert "vie" in result
    end
  end

  describe "levenshtein_close?/2" do
    test "retourne true pour des mots identiques" do
      assert SimilarityCalculator.levenshtein_close?("test", "test") == true
    end

    test "retourne true pour des mots proches" do
      assert SimilarityCalculator.levenshtein_close?("test", "tast") == true
    end

    test "retourne false pour des mots trop différents en longueur" do
      assert SimilarityCalculator.levenshtein_close?("ab", "abcdef") == false
    end

    test "retourne false pour des mots complètement différents" do
      assert SimilarityCalculator.levenshtein_close?("abcd", "wxyz") == false
    end
  end
end
