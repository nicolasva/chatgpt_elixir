defmodule Chatgpt.Memory do
  @moduledoc """
  Gestion de la mémoire de session dans CouchDB chatgpt_memory.
  Équivalent du modèle Memory Ruby (CouchRest).
  """

  @couch_url Application.compile_env(:chatgpt, :couchdb_url, "http://admin:admin@127.0.0.1:5984")
  @db_name "chatgpt_memory"
  @design_name "memory"
  @view_name "by_session"

  defp db_url, do: "#{@couch_url}/#{@db_name}"

  @doc "Assure que la vue CouchDB existe."
  def ensure_views! do
    design_url = "#{db_url()}/_design/#{@design_name}"

    case Req.get(design_url) do
      {:ok, %{status: 200}} ->
        :ok

      _ ->
        design_doc = %{
          "_id" => "_design/#{@design_name}",
          "views" => %{
            @view_name => %{
              "map" =>
                "function(doc) { if (doc.session_id) { emit(doc.session_id, null); } }"
            }
          }
        }

        Req.put(design_url, json: design_doc)
        :ok
    end
  end

  @doc "Récupère tous les messages d'une session."
  def find_by_session(session_id) do
    view_url =
      "#{db_url()}/_design/#{@design_name}/_view/#{@view_name}?key=#{Jason.encode!(session_id)}&include_docs=true"

    case Req.get(view_url) do
      {:ok, %{status: 200, body: body}} ->
        body
        |> Map.get("rows", [])
        |> Enum.map(fn r -> Map.get(r, "doc", %{}) end)
        |> Enum.sort_by(fn d -> Map.get(d, "inserted_at", "") end)

      _ ->
        []
    end
  rescue
    _ -> []
  end

  @doc "Sauvegarde un message en mémoire."
  def create(session_id: session_id, role: role, content: content) do
    doc = %{
      "session_id" => session_id,
      "role" => role,
      "content" => content,
      "inserted_at" => DateTime.utc_now() |> DateTime.to_iso8601()
    }

    Req.post(db_url(), json: doc)
  end

  def create(attrs) when is_map(attrs) do
    doc =
      Map.merge(attrs, %{
        "inserted_at" => DateTime.utc_now() |> DateTime.to_iso8601()
      })

    Req.post(db_url(), json: doc)
  end
end
