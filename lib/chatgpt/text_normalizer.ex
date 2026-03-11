defmodule Chatgpt.TextNormalizer do
  @moduledoc """
  Normalise et nettoie les textes pour la comparaison et l'extraction de mots-clés.
  """

  @doc "Normalise un texte : minuscules, suppression ponctuation, découpage en mots."
  def normalize(text) do
    text
    |> String.downcase()
    |> String.replace(~r/['''`\x{2018}\x{2019}\-]/u, " ")
    |> String.replace(~r/[^a-z\x{00E0}-\x{00FF}0-9\s]/u, "")
    |> String.split()
  end

  @doc "Supprime les accents d'un mot."
  def strip_accents(word) do
    word
    |> String.graphemes()
    |> Enum.map(&replace_accent/1)
    |> Enum.join()
  end

  defp replace_accent("à"), do: "a"
  defp replace_accent("â"), do: "a"
  defp replace_accent("ä"), do: "a"
  defp replace_accent("á"), do: "a"
  defp replace_accent("ã"), do: "a"
  defp replace_accent("å"), do: "a"
  defp replace_accent("è"), do: "e"
  defp replace_accent("é"), do: "e"
  defp replace_accent("ê"), do: "e"
  defp replace_accent("ë"), do: "e"
  defp replace_accent("ì"), do: "i"
  defp replace_accent("í"), do: "i"
  defp replace_accent("î"), do: "i"
  defp replace_accent("ï"), do: "i"
  defp replace_accent("ò"), do: "o"
  defp replace_accent("ó"), do: "o"
  defp replace_accent("ô"), do: "o"
  defp replace_accent("ö"), do: "o"
  defp replace_accent("õ"), do: "o"
  defp replace_accent("ù"), do: "u"
  defp replace_accent("ú"), do: "u"
  defp replace_accent("û"), do: "u"
  defp replace_accent("ü"), do: "u"
  defp replace_accent("ý"), do: "y"
  defp replace_accent("ÿ"), do: "y"
  defp replace_accent("ñ"), do: "n"
  defp replace_accent("ç"), do: "c"
  defp replace_accent(c), do: c
end
