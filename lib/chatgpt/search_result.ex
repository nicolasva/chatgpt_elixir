defmodule Chatgpt.SearchResult do
  @moduledoc """
  Value object représentant le résultat d'une recherche externe.
  Immuable, comparable par valeur (source + content).
  """

  @web_sources ["Wikipedia", "DuckDuckGo", "Tavily"]

  @enforce_keys [:source, :content]
  defstruct [:source, :content]

  def web_sources, do: @web_sources

  def from_wikipedia(content),
    do: %__MODULE__{source: "Wikipedia", content: to_string(content)}

  def from_duckduckgo(content),
    do: %__MODULE__{source: "DuckDuckGo", content: to_string(content)}

  def from_tavily(content),
    do: %__MODULE__{source: "Résultats Tavily", content: to_string(content)}

  def none, do: %__MODULE__{source: "", content: ""}

  def present?(%__MODULE__{content: content}), do: content != ""

  def web_result?(%__MODULE__{source: source}),
    do: Enum.any?(@web_sources, fn s -> String.contains?(source, s) end)

  def substantial?(%__MODULE__{source: source, content: content} = result),
    do: present?(result) and String.length(content) > String.length(source) + 15

  def format(%__MODULE__{source: source, content: content}) do
    if String.starts_with?(source, "Résultats") do
      "#{source} :\n#{content}"
    else
      "D'après #{source} : #{content}"
    end
  end
end
