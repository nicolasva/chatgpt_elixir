defmodule Chatgpt.UserMessage do
  @moduledoc """
  Value object représentant le message d'un utilisateur dans une session.
  Immuable, encapsule les comportements liés à l'analyse du message.
  """

  @question_words ~w(qui que quoi quel quelle quels quelles où comment pourquoi quand combien est-ce)
  @weather_words ~w(temps météo meteo température temperature climat pluie soleil neige vent chaud froid)

  @enforce_keys [:raw, :session_id, :normalized, :keywords]
  defstruct [:raw, :session_id, :normalized, :keywords]

  @doc "Crée un nouveau UserMessage à partir du texte brut et de l'ID de session."
  def new(raw, session_id) do
    raw = String.trim(to_string(raw))

    %__MODULE__{
      raw: raw,
      session_id: session_id,
      normalized: Chatgpt.TextNormalizer.normalize(raw),
      keywords: Chatgpt.KeywordExtractor.extract(raw)
    }
  end

  @doc "Vérifie si le message est une question."
  def question?(%__MODULE__{raw: raw, normalized: normalized}) do
    String.contains?(raw, "?") or
      Enum.any?(normalized, fn w -> w in @question_words end)
  end

  @doc "Vérifie si le message est lié à la météo."
  def weather_related?(%__MODULE__{normalized: normalized}) do
    Enum.any?(normalized, fn w -> w in @weather_words end)
  end

  def weather_words, do: @weather_words

  defimpl String.Chars do
    def to_string(%Chatgpt.UserMessage{raw: raw}), do: raw
  end
end
