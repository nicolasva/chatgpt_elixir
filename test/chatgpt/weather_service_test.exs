defmodule Chatgpt.WeatherServiceTest do
  use ExUnit.Case, async: true

  alias Chatgpt.WeatherService

  describe "extract_city/1" do
    test "extrait la ville après 'à'" do
      assert WeatherService.extract_city("quel temps fait-il à Paris") == "paris"
    end

    test "extrait une ville composée" do
      assert WeatherService.extract_city("météo à new york") == "new york"
    end

    test "extrait la ville après 'au'" do
      assert WeatherService.extract_city("quel temps au havre") == "havre"
    end

    test "extrait la ville après 'en'" do
      assert WeatherService.extract_city("quel temps en bretagne") == "bretagne"
    end

    test "retourne nil sans préposition de lieu" do
      assert WeatherService.extract_city("quel temps fait-il") == nil
    end
  end
end
