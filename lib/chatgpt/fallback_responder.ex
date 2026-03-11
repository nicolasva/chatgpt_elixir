defmodule Chatgpt.FallbackResponder do
  @moduledoc """
  Génère une réponse de fallback quand aucune entrée du dataset ne correspond.
  Priorité : météo → question factuelle (recherche web) → sentiment → défaut.
  """

  @positive_words ~w(bien super génial parfait parfaitement cool top excellent magnifique content contente heureux heureuse formidable nickel impeccable extra chouette trop adore aime fantastique merveilleux)
  @negative_words ~w(mal triste nul horrible mauvais moche ennui ennuie fatigue fatigué peur stress stressé déprimé marre chiant pénible bof)
  @opinion_adjectives ~w(
    beau belle beaux belles joli jolie jolis jolies moche moches
    bien mal bon bonne bons bonnes mauvais mauvaise
    grand grande grands grandes petit petite petits petites
    intéressant intéressante ennuyeux ennuyeuse
    facile difficile important importante normal normale
    vrai vraie faux fausse possible impossible
    sympa gentil gentille méchant méchante
  )

  @positive_responses [
    "Super ! Ça fait plaisir à entendre !",
    "Génial ! Content pour toi !",
    "Top ! Continue comme ça !",
    "Ça fait plaisir ! 😊"
  ]

  @negative_responses [
    "Oh, désolé d'entendre ça. Tu veux en parler ?",
    "Courage ! Ça va aller mieux.",
    "Je suis là si tu as besoin de parler.",
    "Pas facile... Qu'est-ce qui ne va pas ?"
  ]

  @question_responses [
    "Bonne question ! Malheureusement je n'ai pas la réponse.",
    "Hmm, je ne suis pas sûr. Essaie de reformuler !",
    "Je ne connais pas la réponse, mais c'est intéressant comme question !"
  ]

  @default_responses [
    "Intéressant ! Dis-m'en plus.",
    "D'accord ! Quoi d'autre ?",
    "Je vois ! Continue.",
    "Ah oui ? Raconte-moi plus !",
    "C'est noté ! Autre chose ?"
  ]

  def positive_responses, do: @positive_responses
  def negative_responses, do: @negative_responses
  def question_responses, do: @question_responses
  def default_responses, do: @default_responses

  @doc "Génère une réponse de fallback pour un UserMessage."
  def call(%Chatgpt.UserMessage{} = msg) do
    cond do
      Chatgpt.UserMessage.weather_related?(msg) ->
        weather_answer = Chatgpt.WeatherService.search(msg.raw)
        weather_answer || Enum.random(@default_responses)

      Chatgpt.UserMessage.question?(msg) && !opinion_question?(msg) ->
        Chatgpt.WebSearchOrchestrator.search(msg.raw) || Enum.random(@question_responses)

      Chatgpt.UserMessage.question?(msg) && opinion_question?(msg) ->
        Enum.random(@question_responses)

      Enum.any?(msg.normalized, fn w -> w in @positive_words end) ->
        Enum.random(@positive_responses)

      Enum.any?(msg.normalized, fn w -> w in @negative_words end) ->
        Enum.random(@negative_responses)

      true ->
        Enum.random(@default_responses)
    end
  end

  def call(raw) when is_binary(raw) do
    call(Chatgpt.UserMessage.new(raw, nil))
  end

  defp opinion_question?(msg) do
    raw = String.downcase(msg.raw)

    has_pattern =
      Regex.match?(
        ~r/\b(est[\s\-]ce\s+que?\b|est\s+que?\b|c\s*est\b|tu\s+trouves?\b|tu\s+penses?\b|tu\s+crois?\b|tu\s+aimes?\b)/i,
        raw
      )

    has_adjective = Enum.any?(msg.normalized, fn w -> w in @opinion_adjectives end)
    has_pattern && has_adjective
  end
end
