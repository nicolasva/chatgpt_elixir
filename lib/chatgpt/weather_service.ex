defmodule Chatgpt.WeatherService do
  @moduledoc """
  Service météo via wttr.in. Détecte la ville dans le message et retourne la météo.
  """

  require Logger

  @weather_words ~w(temps météo meteo température temperature climat pluie soleil neige vent chaud froid)
  @question_words ~w(qui que quoi quel quelle quels quelles où comment pourquoi quand combien est-ce)
  @city_prepositions ~w(à a au en sur)

  def weather_words, do: @weather_words

  @doc "Recherche la météo à partir du message (avec cache Redis 30 min)."
  def search(message) do
    city = extract_city(message) || "Paris"
    Chatgpt.CachedSearch.search("weather", city, fn -> fetch_weather(city) end, ttl: 1_800)
  end

  defp fetch_weather(city) do
    encoded_city = URI.encode(city, &URI.char_unreserved?/1)
    url = "https://wttr.in/#{encoded_city}?format=j1&lang=fr"

    case Req.get(url, receive_timeout: 10_000) do
      {:ok, %{status: 200, body: body}} ->
        current = body |> Map.get("current_condition", []) |> List.first()

        if current do
          temp = current["temp_C"]
          feels_like = current["FeelsLikeC"]
          humidity = current["humidity"]

          description =
            get_in(current, ["lang_fr", Access.at(0), "value"]) ||
              get_in(current, ["weatherDesc", Access.at(0), "value"])

          "Météo à #{String.capitalize(city)} : #{description}, #{temp}°C (ressenti #{feels_like}°C), humidité #{humidity}%."
        else
          nil
        end

      _ ->
        nil
    end
  rescue
    e ->
      Logger.error("[WeatherService] Erreur : #{Exception.message(e)}")
      nil
  end

  @doc "Extrait le nom de la ville depuis un message."
  def extract_city(message) do
    words =
      message
      |> String.downcase()
      |> String.replace(~r/[?!.,]/, "")
      |> String.split()

    words
    |> Enum.with_index()
    |> Enum.find_value(fn {w, i} ->
      if w in @city_prepositions && i + 1 < length(words) do
        city_parts =
          Enum.slice(words, (i + 1)..(length(words) - 1))
          |> Enum.take_while(fn word ->
            word not in @weather_words and
              word not in @question_words and
              word not in ~w(aujourd'hui demain ce cette)
          end)

        if city_parts != [], do: Enum.join(city_parts, " "), else: nil
      end
    end)
  end
end
