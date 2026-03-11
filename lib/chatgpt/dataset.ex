defmodule Chatgpt.Dataset do
  @moduledoc """
  Accès au dataset CouchDB chatgpt_dataset.
  Équivalent du modèle Dataset Ruby (CouchRest).
  """

  @couch_url Application.compile_env(:chatgpt, :couchdb_url, "http://admin:admin@127.0.0.1:5984")
  @db_name "chatgpt_dataset"
  @dataset_path :code.priv_dir(:chatgpt) |> to_string() |> Path.join("dataset.json")

  defp db_url, do: "#{@couch_url}/#{@db_name}"

  @doc "Retourne tous les documents du dataset."
  def all do
    case Req.get("#{db_url()}/_all_docs?include_docs=true") do
      {:ok, %{status: 200, body: body}} ->
        body
        |> Map.get("rows", [])
        |> Enum.map(fn r -> Map.get(r, "doc", %{}) end)
        |> Enum.reject(fn doc -> Map.get(doc, "_id", "") |> String.starts_with?("_") end)

      _ ->
        []
    end
  end

  @doc "Crée un nouveau document dans le dataset."
  def create(attrs) do
    case Req.post(db_url(), json: attrs) do
      {:ok, %{status: status, body: body}} when status in [201, 200] ->
        {:ok, Map.merge(attrs, %{"_id" => body["id"], "_rev" => body["rev"]})}

      {:ok, %{status: status}} ->
        {:error, "HTTP #{status}"}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc "Supprime un document du dataset."
  def delete(%{"_id" => id, "_rev" => rev}) do
    Req.delete("#{db_url()}/#{id}?rev=#{rev}")
  end

  def delete(_), do: {:error, :missing_id_rev}

  @doc "Charge le dataset depuis le fichier JSON si la base est vide."
  def seed_if_empty! do
    docs = all()

    if Enum.empty?(docs) and File.exists?(@dataset_path) do
      ensure_db_exists!()
      json_data = File.read!(@dataset_path) |> Jason.decode!()
      Enum.each(json_data, fn d -> create(d) end)
      require Logger
      Logger.info("[Dataset] #{length(json_data)} entrées importées depuis dataset.json")
      all()
    else
      docs
    end
  end

  @doc "Cherche les documents dont la question matche exactement."
  def find_by_question(question) do
    normalized = String.downcase(String.trim(question))
    all()
    |> Enum.filter(fn d ->
      Map.get(d, "question", "") |> String.downcase() |> String.trim() == normalized
    end)
  end

  defp ensure_db_exists! do
    Req.put(db_url())
  end
end
