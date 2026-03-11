defmodule Chatgpt.ChatService do
  @moduledoc """
  Orchestrateur principal du chatbot.
  Gère le cycle complet : dataset → fallback web → apprentissage → mémoire.
  """

  require Logger

  @doc "Traite un message utilisateur et retourne la réponse du bot."
  def predict(raw_message, session_id) do
    msg = Chatgpt.UserMessage.new(raw_message, session_id)

    Chatgpt.Memory.create(
      session_id: session_id,
      role: "user",
      content: msg.raw
    )

    answer =
      case Chatgpt.DatasetQuery.find_best_match(msg.raw) do
        nil ->
          reply = Chatgpt.FallbackResponder.call(msg)
          Chatgpt.AutoLearner.handle_fallback(session_id, msg, reply)
          reply

        match ->
          Chatgpt.AutoLearner.learn_pending(session_id, match["answer"])
          match["answer"]
      end

    Chatgpt.Memory.create(
      session_id: session_id,
      role: "bot",
      content: answer
    )

    answer
  end
end
