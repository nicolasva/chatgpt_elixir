defmodule Chatgpt.KeywordExtractorTest do
  use ExUnit.Case, async: true

  alias Chatgpt.KeywordExtractor

  describe "extract/1" do
    test "supprime les articles et prépositions" do
      result = KeywordExtractor.extract("le chat de la maison")
      assert "chat" in result
      assert "maison" in result
      refute "le" in result
      refute "de" in result
      refute "la" in result
    end

    test "supprime les mots interrogatifs" do
      result = KeywordExtractor.extract("qui a inventé le téléphone")
      assert "téléphone" in result
      refute "qui" in result
    end

    test "garde les mots significatifs pour 'mission impossible'" do
      result = KeywordExtractor.extract("qui a joué dans mission impossible")
      assert "mission" in result
      assert "impossible" in result
      refute "qui" in result
      refute "dans" in result
      refute "joué" in result
    end

    test "garde les mots significatifs pour un pays" do
      result = KeywordExtractor.extract("quel est le pays le plus visité dans le monde")
      assert "visité" in result
      assert "monde" in result
      refute "quel" in result
      refute "est" in result
      refute "le" in result
      refute "dans" in result
    end

    test "retourne un tableau vide pour une phrase de stop words" do
      result = KeywordExtractor.extract("qui est ce que tu es")
      assert result == []
    end

    test "supprime les mots de moins de 2 caractères" do
      result = KeywordExtractor.extract("a y va")
      Enum.each(result, fn w -> assert String.length(w) >= 2 end)
    end

    test "garde les noms propres en minuscules" do
      result = KeywordExtractor.extract("qui est Napoleon Bonaparte")
      assert "napoleon" in result
      assert "bonaparte" in result
    end

    test "garde les acronymes" do
      result = KeywordExtractor.extract("quels pays composent le g8")
      assert "g8" in result
    end

    test "supprime les verbes de création" do
      result = KeywordExtractor.extract("qui a créé Python")
      assert "python" in result
      refute "créé" in result
    end
  end
end
