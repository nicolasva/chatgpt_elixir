defmodule ChatgptWeb.PageControllerTest do
  use ChatgptWeb.ConnCase

  test "GET / affiche l'interface de chat", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert html_response(conn, 200) =~ "Mini ChatGPT"
  end
end
