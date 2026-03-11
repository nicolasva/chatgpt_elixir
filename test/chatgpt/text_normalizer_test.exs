defmodule Chatgpt.TextNormalizerTest do
  use ExUnit.Case, async: true

  alias Chatgpt.TextNormalizer

  describe "normalize/1" do
    test "met le texte en minuscules" do
      assert TextNormalizer.normalize("BONJOUR") == ["bonjour"]
    end

    test "supprime la ponctuation" do
      assert TextNormalizer.normalize("bonjour, comment ça va ?") == ["bonjour", "comment", "ça", "va"]
    end

    test "remplace les apostrophes par des espaces" do
      assert TextNormalizer.normalize("l'hôpital") == ["l", "hôpital"]
    end

    test "remplace les tirets par des espaces" do
      assert TextNormalizer.normalize("saint-malo") == ["saint", "malo"]
    end

    test "conserve les caractères accentués" do
      assert TextNormalizer.normalize("éléphant") == ["éléphant"]
    end

    test "conserve les chiffres" do
      assert TextNormalizer.normalize("g8 g20") == ["g8", "g20"]
    end

    test "retourne un tableau vide pour une chaîne vide" do
      assert TextNormalizer.normalize("") == []
    end

    test "gère les espaces multiples" do
      assert TextNormalizer.normalize("  bonjour   monde  ") == ["bonjour", "monde"]
    end

    test "gère les apostrophes typographiques" do
      assert TextNormalizer.normalize("l\u2019école") == ["l", "école"]
    end
  end

  describe "strip_accents/1" do
    test "supprime les accents aigus" do
      assert TextNormalizer.strip_accents("éléphant") == "elephant"
    end

    test "supprime les accents graves" do
      assert TextNormalizer.strip_accents("père") == "pere"
    end

    test "supprime les accents circonflexes" do
      assert TextNormalizer.strip_accents("hôpital") == "hopital"
    end

    test "supprime les trémas" do
      assert TextNormalizer.strip_accents("naïf") == "naif"
    end

    test "supprime les cédilles" do
      assert TextNormalizer.strip_accents("français") == "francais"
    end

    test "ne modifie pas les caractères sans accent" do
      assert TextNormalizer.strip_accents("bonjour") == "bonjour"
    end

    test "gère une combinaison d'accents" do
      assert TextNormalizer.strip_accents("àéîôùç") == "aeiouc"
    end
  end
end
