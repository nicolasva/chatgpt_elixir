defmodule ChatgptWeb.ChatController do
  use ChatgptWeb, :controller

  @doc "Affiche l'interface de chat principale."
  def index(conn, _params) do
    render(conn, :index)
  end

  @doc "Traite un message et retourne la réponse du bot en JSON."
  def chat(conn, %{"message" => message}) do
    session_id = get_session(conn, :session_id) || generate_session_id()
    conn = put_session(conn, :session_id, session_id)

    reply = Chatgpt.ChatService.predict(message, session_id)

    conn
    |> put_resp_content_type("application/json")
    |> json(%{reply: reply})
  end

  def chat(conn, _params) do
    conn
    |> put_status(400)
    |> json(%{error: "Paramètre 'message' manquant"})
  end

  defp generate_session_id do
    :crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)
  end
end
