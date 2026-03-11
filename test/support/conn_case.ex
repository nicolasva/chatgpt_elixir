defmodule ChatgptWeb.ConnCase do
  @moduledoc """
  Module de support pour les tests de controllers Phoenix.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      @endpoint ChatgptWeb.Endpoint

      use ChatgptWeb, :verified_routes

      import Plug.Conn
      import Phoenix.ConnTest
      import ChatgptWeb.ConnCase
    end
  end

  setup do
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end
end
