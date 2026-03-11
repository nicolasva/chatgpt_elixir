defmodule Chatgpt.Chat do
  @moduledoc """
  Context principal du chatbot.
  Point d'entrée unique pour le web layer — le controller n'appelle que ce module.
  """

  alias Chatgpt.{ChatService, Memory}

  @doc "Traite un message et retourne la réponse du bot."
  defdelegate predict(raw_message, session_id), to: ChatService

  @doc "Retourne l'historique de conversation d'une session."
  defdelegate conversation_history(session_id), to: Memory, as: :find_by_session
end
