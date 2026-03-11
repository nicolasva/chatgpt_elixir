defmodule Chatgpt.DataCase do
  @moduledoc """
  Module de support pour les tests nécessitant l'accès aux données (CouchDB).
  Pas de sandbox SQL — l'application utilise CouchDB via Req.
  """

  use ExUnit.CaseTemplate
end
