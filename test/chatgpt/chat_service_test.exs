defmodule Chatgpt.ChatServiceTest do
  use ExUnit.Case

  @moduletag :integration

  alias Chatgpt.ChatService
  alias Chatgpt.Memory

  # Ces tests nécessitent CouchDB + les GenServers démarrés (AutoLearner, etc.)
  # Lance-les avec : mix test --include integration

  describe "predict/2 — questions du dataset" do
    setup do
      session_id = "exunit-#{:crypto.strong_rand_bytes(4) |> Base.encode16(case: :lower)}"
      {:ok, session_id: session_id}
    end

    test "retourne 'Salut, comment ça va ?' pour 'bonjour'", %{session_id: sid} do
      assert ChatService.predict("bonjour", sid) == "Salut, comment ça va ?"
    end

    test "retourne 'Salut !' pour 'salut'", %{session_id: sid} do
      assert ChatService.predict("salut", sid) == "Salut !"
    end

    test "retourne une réponse cohérente pour 'merci'", %{session_id: sid} do
      response = ChatService.predict("merci", sid)
      assert is_binary(response)
      assert String.length(response) > 0
    end

    test "retourne '42, évidemment !' pour 'quel est le sens de la vie'", %{session_id: sid} do
      assert ChatService.predict("quel est le sens de la vie", sid) == "42, évidemment !"
    end

    test "retourne une blague pour 'raconte-moi une blague'", %{session_id: sid} do
      response = ChatService.predict("raconte-moi une blague", sid)
      assert String.contains?(response, "plongeurs")
    end

    test "retourne l'identité pour 'qui es-tu'", %{session_id: sid} do
      response = ChatService.predict("qui es-tu", sid)
      assert String.contains?(response, "logiciel")
    end

    test "retourne une réponse pour 'hello'", %{session_id: sid} do
      assert ChatService.predict("hello", sid) == "Hello ! How can I help you ?"
    end

    test "retourne une réponse pour 'au revoir'", %{session_id: sid} do
      assert ChatService.predict("au revoir", sid) == "Au revoir ! À bientôt !"
    end
  end

  describe "predict/2 — mémoire" do
    test "sauvegarde les messages en mémoire" do
      session_id = "exunit-mem-#{:crypto.strong_rand_bytes(4) |> Base.encode16(case: :lower)}"
      ChatService.predict("bonjour", session_id)
      memory = Memory.find_by_session(session_id)
      assert length(memory) == 2
      roles = Enum.map(memory, & &1["role"])
      assert "user" in roles
      assert "bot" in roles
    end
  end

  # ---------------------------------------------------------------------------
  # Tests API externes (lents, tagged :slow + :integration)
  # ---------------------------------------------------------------------------

  describe "predict/2 — recherche web" do
    setup do
      session_id = "exunit-slow-#{:crypto.strong_rand_bytes(4) |> Base.encode16(case: :lower)}"
      {:ok, session_id: session_id}
    end

    @tag :slow
    test "trouve Tom Cruise pour 'qui a joué dans mission impossible'", %{session_id: sid} do
      response = ChatService.predict("qui a joué dans mission impossible", sid)
      assert String.contains?(response, "Tom Cruise")
    end

    @tag :slow
    test "trouve des données sur les pays les plus visités", %{session_id: sid} do
      response = ChatService.predict("quel est le pays le plus visité dans le monde", sid)
      answer = String.downcase(response)
      assert String.contains?(answer, "france") or
               String.contains?(answer, "pays") or
               String.contains?(answer, "visité")
    end

    @tag :slow
    test "retourne des informations Wikipedia pour 'quels pays composent le g8'", %{session_id: sid} do
      response = ChatService.predict("quels pays composent le g8", sid)
      assert String.contains?(response, "Wikipedia") or
               String.contains?(response, "G7") or
               String.contains?(response, "G8")
    end

    @tag :slow
    test "retourne la météo pour 'quel temps fait-il à Paris'", %{session_id: sid} do
      response = ChatService.predict("quel temps fait-il à Paris", sid)
      assert String.starts_with?(response, "Météo à")
    end

    @tag :slow
    test "retourne des infos sur le Titanic pour 'qui a joué dans Titanic'", %{session_id: sid} do
      response = ChatService.predict("qui a joué dans Titanic", sid)
      answer = String.downcase(response)
      assert String.contains?(answer, "dicaprio") or
               String.contains?(answer, "kate") or
               String.contains?(answer, "winslet") or
               String.contains?(answer, "cameron")
    end

    @tag :slow
    test "retourne des infos pour 'où se trouve Erquy'", %{session_id: sid} do
      response = ChatService.predict("où se trouve Erquy", sid)
      assert String.contains?(response, "Wikipedia")
    end
  end
end
