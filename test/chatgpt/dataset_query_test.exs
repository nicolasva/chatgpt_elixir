defmodule Chatgpt.DatasetQueryTest do
  use ExUnit.Case, async: true

  alias Chatgpt.DatasetQuery

  # Charge le dataset directement depuis le fichier JSON sans passer par CouchDB ni AutoLearner
  @dataset_path Path.join(:code.priv_dir(:chatgpt), "dataset.json")

  setup_all do
    docs = File.read!(@dataset_path) |> Jason.decode!()
    {:ok, docs: docs}
  end

  defp find(query, docs), do: DatasetQuery.find_best_match(query, docs)

  # ---------------------------------------------------------------------------
  # Match exact
  # ---------------------------------------------------------------------------

  describe "match exact" do
    test "trouve 'bonjour'", %{docs: docs} do
      match = find("bonjour", docs)
      assert match != nil
      assert match["answer"] == "Salut, comment ça va ?"
    end

    test "trouve 'salut'", %{docs: docs} do
      match = find("salut", docs)
      assert match != nil
      assert match["answer"] == "Salut !"
    end

    test "trouve 'merci'", %{docs: docs} do
      match = find("merci", docs)
      assert match != nil
      assert match["answer"] == "De rien, avec plaisir !"
    end

    test "trouve 'au revoir'", %{docs: docs} do
      match = find("au revoir", docs)
      assert match != nil
      assert match["answer"] == "Au revoir ! À bientôt !"
    end

    test "trouve 'bye'", %{docs: docs} do
      match = find("bye", docs)
      assert match != nil
      assert match["answer"] == "Bye bye ! Reviens quand tu veux !"
    end

    test "trouve 'quel est le sens de la vie'", %{docs: docs} do
      match = find("quel est le sens de la vie", docs)
      assert match != nil
      assert match["answer"] == "42, évidemment !"
    end

    test "trouve 'qui es-tu'", %{docs: docs} do
      match = find("qui es-tu", docs)
      assert match != nil
      assert match["answer"] == "Je suis un simple logiciel, écrit pour répéter ce qu'on m'a appris."
    end

    test "trouve 'raconte-moi une blague'", %{docs: docs} do
      match = find("raconte-moi une blague", docs)
      assert match != nil
      assert String.contains?(match["answer"], "plongeurs")
    end

    test "trouve 'lol'", %{docs: docs} do
      match = find("lol", docs)
      assert match != nil
      assert match["answer"] == "Haha content de te faire rire !"
    end

    test "trouve 'je suis triste'", %{docs: docs} do
      match = find("je suis triste", docs)
      assert match != nil
      assert String.contains?(match["answer"], "Dis-moi ce qui ne va pas")
    end

    test "trouve 'je suis content'", %{docs: docs} do
      match = find("je suis content", docs)
      assert match != nil
      assert String.contains?(match["answer"], "plaisir")
    end

    test "trouve 'comment tu t'appelles'", %{docs: docs} do
      match = find("comment tu t'appelles", docs)
      assert match != nil
      assert String.contains?(match["answer"], "MiniGPT")
    end

    test "trouve 'quel est ton age'", %{docs: docs} do
      match = find("quel est ton age", docs)
      assert match != nil
      assert String.contains?(match["answer"], "jeune")
    end

    test "trouve 'hello'", %{docs: docs} do
      match = find("hello", docs)
      assert match != nil
      assert match["answer"] == "Hello ! How can I help you ?"
    end

    test "trouve 'bonsoir'", %{docs: docs} do
      match = find("bonsoir", docs)
      assert match != nil
      assert String.contains?(match["answer"], "Bonsoir")
    end

    test "trouve 'bonne nuit'", %{docs: docs} do
      match = find("bonne nuit", docs)
      assert match != nil
      assert String.contains?(match["answer"], "rêves")
    end
  end

  # ---------------------------------------------------------------------------
  # Réponses multiples (random)
  # ---------------------------------------------------------------------------

  describe "réponses multiples (random)" do
    test "retourne une des réponses possibles pour 'salut comment ca va'", %{docs: docs} do
      match = find("salut comment ca va", docs)
      assert match != nil
      assert match["answer"] in ["Bien, merci !", "Très bien, merci"]
    end

    test "retourne une des réponses possibles pour 'bonjour comment ca va'", %{docs: docs} do
      match = find("bonjour comment ca va", docs)
      assert match != nil
      assert match["answer"] in ["Okay", "Génial", "Ça pourrait aller mieux", "Comme ci, comme ça"]
    end

    test "retourne une des réponses possibles pour 'quoi de neuf'", %{docs: docs} do
      match = find("quoi de neuf", docs)
      assert match != nil
      possible = ["Rien de nouveau, et toi ?", "Tout baigne !", "Le chiffre avant 10, sinon, toi, quoi de neuf ?"]
      assert match["answer"] in possible
    end

    test "retourne une des réponses pour 'comment vas-tu'", %{docs: docs} do
      match = find("comment vas-tu", docs)
      assert match != nil
      assert match["answer"] in ["Je vais bien, et vous ?", "Je vais bien, et toi ?"]
    end
  end

  # ---------------------------------------------------------------------------
  # Matching Jaccard
  # ---------------------------------------------------------------------------

  describe "matching Jaccard" do
    test "matche 'qui es tu' (sans tiret) avec 'qui es-tu'", %{docs: docs} do
      match = find("qui es tu", docs)
      assert match != nil
    end

    test "matche 'ca va' avec entrée du dataset", %{docs: docs} do
      match = find("ca va", docs)
      assert match != nil
      assert String.contains?(match["answer"], "merci")
    end
  end

  # ---------------------------------------------------------------------------
  # Vie du robot
  # ---------------------------------------------------------------------------

  describe "vie du robot" do
    test "trouve 'bois-tu'", %{docs: docs} do
      match = find("bois-tu", docs)
      assert match != nil
      assert String.contains?(match["answer"], "boisson")
    end

    test "trouve 'est-ce que tu bois'", %{docs: docs} do
      match = find("est-ce que tu bois", docs)
      assert match != nil
      assert String.contains?(match["answer"], "boisson")
    end

    test "trouve 'un robot peut-il etre saoul'", %{docs: docs} do
      match = find("un robot peut-il etre saoul", docs)
      assert match != nil
      assert String.contains?(match["answer"], "pompette")
    end

    test "trouve 'peux-tu faire du mal a un humain'", %{docs: docs} do
      match = find("peux-tu faire du mal a un humain", docs)
      assert match != nil
      assert String.contains?(match["answer"], "première loi")
    end

    test "trouve 'parle-moi de toi'", %{docs: docs} do
      match = find("parle-moi de toi", docs)
      assert match != nil
      assert String.contains?(match["answer"], "MiniGPT")
    end

    test "trouve 'où te trouves-tu'", %{docs: docs} do
      match = find("où te trouves-tu", docs)
      assert match != nil
      assert match["answer"] == "Partout !"
    end

    test "trouve 'quelle est ton adresse'", %{docs: docs} do
      match = find("quelle est ton adresse", docs)
      assert match != nil
      assert String.contains?(match["answer"], "Internet")
    end

    test "trouve 'où es-tu'", %{docs: docs} do
      match = find("où es-tu", docs)
      assert match != nil
      assert String.contains?(match["answer"], "Internet")
    end

    test "trouve 'quel est ton numero'", %{docs: docs} do
      match = find("quel est ton numero", docs)
      assert match != nil
      assert match["answer"] == "Je n'ai pas de numéro."
    end

    test "trouve 'pourquoi ne manges-tu pas de nourriture'", %{docs: docs} do
      match = find("pourquoi ne manges-tu pas de nourriture", docs)
      assert match != nil
      assert String.contains?(match["answer"], "programme informatique")
    end

    test "trouve 'qui est ton patron'", %{docs: docs} do
      match = find("qui est ton patron", docs)
      assert match != nil
      assert String.contains?(match["answer"], "auto-entrepreneur")
    end

    test "trouve 'quel age as-tu'", %{docs: docs} do
      match = find("quel age as-tu", docs)
      assert match != nil
      assert String.contains?(match["answer"], "jeune")
    end
  end

  # ---------------------------------------------------------------------------
  # Variantes de salutations
  # ---------------------------------------------------------------------------

  describe "variantes de salutations" do
    test "retourne une réponse pour 'salut comment vas-tu'", %{docs: docs} do
      match = find("salut comment vas-tu", docs)
      assert match != nil
    end

    test "retourne une réponse pour 'bonjour comment vas-tu'", %{docs: docs} do
      match = find("bonjour comment vas-tu", docs)
      assert match != nil
      possible = ["Okay", "Génial !", "Je vais bien merci, et toi ?"]
      assert match["answer"] in possible
    end

    test "trouve 'ca va'", %{docs: docs} do
      match = find("ca va", docs)
      assert match != nil
      assert String.contains?(match["answer"], "merci")
    end

    test "trouve 'bonjour ca va'", %{docs: docs} do
      match = find("bonjour ca va", docs)
      assert match != nil
      assert String.contains?(match["answer"], "merci")
    end

    test "trouve 'salut ca va'", %{docs: docs} do
      match = find("salut ca va", docs)
      assert match != nil
      assert String.contains?(match["answer"], "merci")
    end
  end

  # ---------------------------------------------------------------------------
  # Projets et langages
  # ---------------------------------------------------------------------------

  describe "projets et langages" do
    test "trouve 'je travaille sur un projet'", %{docs: docs} do
      match = find("je travaille sur un projet", docs)
      assert match != nil
      assert String.contains?(match["answer"], "travailles")
    end

    test "trouve 'quels langages utilises-tu'", %{docs: docs} do
      match = find("quels langages utilises-tu", docs)
      assert match != nil
      assert String.contains?(match["answer"], "Ruby")
    end

    test "trouve 'que signifie yolo'", %{docs: docs} do
      match = find("que signifie yolo", docs)
      assert match != nil
      assert String.contains?(match["answer"], "vivrais")
    end

    test "trouve 'quels sont tes sujets preferes'", %{docs: docs} do
      match = find("quels sont tes sujets preferes", docs)
      assert match != nil
      assert String.contains?(match["answer"], "robotique")
    end
  end

  # ---------------------------------------------------------------------------
  # Questions pratiques
  # ---------------------------------------------------------------------------

  describe "questions pratiques" do
    test "trouve 'quel jour sommes-nous'", %{docs: docs} do
      match = find("quel jour sommes-nous", docs)
      assert match != nil
      assert String.contains?(match["answer"], "calendrier")
    end

    test "trouve 'quelle heure est-il'", %{docs: docs} do
      match = find("quelle heure est-il", docs)
      assert match != nil
      assert String.contains?(match["answer"], "montre")
    end

    test "trouve 'qu'est ce qui te derange'", %{docs: docs} do
      match = find("qu'est ce qui te derange", docs)
      assert match != nil
      assert String.contains?(match["answer"], "chiffres")
    end

    test "trouve 'quel temps fait-il'", %{docs: docs} do
      match = find("quel temps fait-il", docs)
      assert match != nil
      assert String.contains?(match["answer"], "météo")
    end

    test "trouve 'j'ai besoin d'aide'", %{docs: docs} do
      match = find("j'ai besoin d'aide", docs)
      assert match != nil
      assert String.contains?(match["answer"], "aider")
    end

    test "trouve 'es-tu la'", %{docs: docs} do
      match = find("es-tu la", docs)
      assert match != nil
      assert String.contains?(match["answer"], "là")
    end
  end

  # ---------------------------------------------------------------------------
  # Réponses courtes
  # ---------------------------------------------------------------------------

  describe "réponses courtes" do
    test "trouve 'pourquoi'", %{docs: docs} do
      match = find("pourquoi", docs)
      assert match != nil
      assert String.contains?(match["answer"], "Bonne question")
    end

    test "trouve 'comment'", %{docs: docs} do
      match = find("comment", docs)
      assert match != nil
      assert String.contains?(match["answer"], "préciser")
    end

    test "trouve 'quand'", %{docs: docs} do
      match = find("quand", docs)
      assert match != nil
      assert String.contains?(match["answer"], "contexte")
    end

    test "trouve 'bien'", %{docs: docs} do
      match = find("bien", docs)
      assert match != nil
      assert match["answer"] == "Super !"
    end

    test "trouve 'pas bien'", %{docs: docs} do
      match = find("pas bien", docs)
      assert match != nil
      assert String.contains?(match["answer"], "ne va pas")
    end
  end

  # ---------------------------------------------------------------------------
  # Cohérence des réponses
  # ---------------------------------------------------------------------------

  describe "cohérence des réponses" do
    test "une salutation donne une réponse contenant un mot de salutation", %{docs: docs} do
      greetings = ~w[bonjour salut coucou hey hello bonsoir]

      Enum.each(greetings, fn greeting ->
        match = find(greeting, docs)
        assert match != nil, "Pas de match pour '#{greeting}'"
        answer = String.downcase(match["answer"])

        assert Enum.any?(
                 ["salut", "bonjour", "coucou", "hey", "hello", "bonsoir", "plaisir", "comment"],
                 &String.contains?(answer, &1)
               ),
               "La réponse '#{answer}' ne contient pas de mot de salutation pour '#{greeting}'"
      end)
    end

    test "un au revoir donne une réponse de départ", %{docs: docs} do
      goodbyes = ["au revoir", "bye", "à plus", "bonne nuit", "bonne journée"]

      Enum.each(goodbyes, fn goodbye ->
        match = find(goodbye, docs)
        assert match != nil, "Pas de match pour '#{goodbye}'"
        answer = String.downcase(match["answer"])

        assert Enum.any?(
                 ["revoir", "bientôt", "bye", "nuit", "rêves", "journée", "merci", "reviens"],
                 &String.contains?(answer, &1)
               ),
               "La réponse '#{answer}' ne contient pas de mot de départ pour '#{goodbye}'"
      end)
    end

    test "les questions d'identité mentionnent le bot ou ses caractéristiques", %{docs: docs} do
      identity_qs = ["qui es-tu", "comment tu t'appelles", "c'est quoi ton nom", "tu es un robot", "es-tu humain"]

      Enum.each(identity_qs, fn q ->
        match = find(q, docs)
        assert match != nil, "Pas de match pour '#{q}'"
        answer = String.downcase(match["answer"])

        assert Enum.any?(
                 ["minigpt", "chatbot", "logiciel", "programme", "ruby"],
                 &String.contains?(answer, &1)
               ),
               "La réponse '#{answer}' ne mentionne pas le bot pour '#{q}'"
      end)
    end

    test "les émotions reçoivent une réponse empathique", %{docs: docs} do
      emotions = %{
        "je suis triste" => ["dis-moi", "là pour"],
        "je suis content" => ["super", "plaisir"],
        "je m'ennuie" => ["discuter", "question"],
        "je suis fatigué" => ["repose", "santé"]
      }

      Enum.each(emotions, fn {msg, keywords} ->
        match = find(msg, docs)
        assert match != nil, "Pas de match pour '#{msg}'"
        answer = String.downcase(match["answer"])

        assert Enum.any?(keywords, &String.contains?(answer, &1)),
               "La réponse '#{answer}' ne contient pas de mot empathique pour '#{msg}'"
      end)
    end

    test "les compliments reçoivent un remerciement", %{docs: docs} do
      compliments = ["tu es gentil", "tu es drôle", "tu es intelligent"]

      Enum.each(compliments, fn c ->
        match = find(c, docs)
        assert match != nil, "Pas de match pour '#{c}'"
        answer = String.downcase(match["answer"])

        assert String.contains?(answer, "merci") or String.contains?(answer, "mieux"),
               "La réponse '#{answer}' ne contient pas de remerciement pour '#{c}'"
      end)
    end

    test "les insultes reçoivent une réponse calme", %{docs: docs} do
      insults = ["t'es nul", "tu es bête"]

      Enum.each(insults, fn i ->
        match = find(i, docs)
        assert match != nil, "Pas de match pour '#{i}'"
        answer = String.downcase(match["answer"])

        assert Enum.any?(
                 ["désolé", "apprentissage", "patient"],
                 &String.contains?(answer, &1)
               ),
               "La réponse '#{answer}' n'est pas calme pour '#{i}'"
      end)
    end
  end

  # ---------------------------------------------------------------------------
  # Aucun match
  # ---------------------------------------------------------------------------

  describe "aucun match" do
    test "retourne nil pour une question inconnue", %{docs: docs} do
      assert find("quelle est la masse de Jupiter", docs) == nil
    end

    test "retourne nil pour du charabia", %{docs: docs} do
      assert find("xyzzy plugh abracadabra", docs) == nil
    end

    test "retourne nil pour une question spécialisée", %{docs: docs} do
      assert find("comment fonctionne la photosynthèse", docs) == nil
    end
  end
end
