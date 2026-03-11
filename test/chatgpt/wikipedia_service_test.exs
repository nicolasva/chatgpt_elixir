defmodule Chatgpt.WikipediaServiceTest do
  use ExUnit.Case, async: true

  alias Chatgpt.WikipediaService

  describe "relevant?/2" do
    test "retourne true pour une requête vide" do
      assert WikipediaService.relevant?("some extract", "") == true
    end

    test "retourne true pour une requête nil" do
      assert WikipediaService.relevant?("some extract", nil) == true
    end

    test "retourne true pour une requête avec un seul mot-clé" do
      assert WikipediaService.relevant?("Tom Cruise est un acteur", "acteur") == true
    end

    test "retourne true quand la première phrase contient les mots-clés" do
      extract = "La France est le pays le plus visité au monde. Chaque année, des millions de touristes..."
      query = "quel est le pays le plus visité"
      assert WikipediaService.relevant?(extract, query) == true
    end

    test "retourne false quand la première phrase ne correspond pas" do
      extract = "Le Grand Continent est une revue européenne. Elle publie des articles sur la géopolitique."
      query = "quel est le continent le plus visité"
      assert WikipediaService.relevant?(extract, query) == false
    end

    test "rejette les faux positifs comme Benoît XVI pour 'continent visité'" do
      extract = "Au cours de son pontificat, Benoît XVI a effectué 25 visites pastorales hors d'Italie."
      query = "quel est le continent le plus visité"
      assert WikipediaService.relevant?(extract, query) == false
    end

    test "accepte un extrait pertinent sur le tourisme" do
      extract = "Le tourisme en France est un secteur économique majeur du pays visité par 90 millions de touristes."
      query = "pays le plus visité"
      assert WikipediaService.relevant?(extract, query) == true
    end
  end
end
