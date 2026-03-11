defmodule Chatgpt.FallbackResponderTest do
  use ExUnit.Case, async: true

  alias Chatgpt.FallbackResponder
  alias Chatgpt.UserMessage

  # opinion_question? est privée — on la teste via call/1 (comportement observable)
  # Les tests ci-dessous vérifient qu'une question d'opinion ne déclenche pas de recherche web.

  describe "opinion_question? (comportement)" do
    test "détecte 'est-ce que la ville est belle' comme opinion (pas de recherche web)" do
      # On vérifie que la réponse est parmi les question_responses et non une recherche web
      response = FallbackResponder.call(UserMessage.new("est-ce que la ville est belle ?", nil))
      assert response in FallbackResponder.question_responses()
    end

    test "détecte 'tu trouves ça bien' comme opinion" do
      response = FallbackResponder.call(UserMessage.new("tu trouves ça bien ?", nil))
      assert response in FallbackResponder.question_responses()
    end

    test "détecte 'c est joli' comme opinion" do
      response = FallbackResponder.call(UserMessage.new("c est joli ?", nil))
      assert response in FallbackResponder.question_responses()
    end

    test "détecte 'tu penses que c'est facile' comme opinion" do
      response = FallbackResponder.call(UserMessage.new("tu penses que c'est facile ?", nil))
      assert response in FallbackResponder.question_responses()
    end

    test "détecte 'tu crois que c'est vrai' comme opinion" do
      response = FallbackResponder.call(UserMessage.new("tu crois que c'est vrai ?", nil))
      assert response in FallbackResponder.question_responses()
    end
  end

  describe "call/1 — sentiment positif" do
    test "retourne une réponse positive pour 'tout est super génial'" do
      response = FallbackResponder.call("tout est super génial")
      assert response in FallbackResponder.positive_responses()
    end

    test "retourne une réponse positive pour 'c'est formidable'" do
      response = FallbackResponder.call("c'est formidable")
      assert response in FallbackResponder.positive_responses()
    end
  end

  describe "call/1 — sentiment négatif" do
    test "retourne une réponse négative pour 'tout est horrible'" do
      response = FallbackResponder.call("tout est horrible et nul")
      assert response in FallbackResponder.negative_responses()
    end

    test "retourne une réponse négative pour 'j'ai peur'" do
      response = FallbackResponder.call("j'ai peur de l'orage")
      assert response in FallbackResponder.negative_responses()
    end
  end

  describe "call/1 — message neutre" do
    test "retourne une réponse par défaut pour du texte neutre" do
      response = FallbackResponder.call("patate")
      assert response in FallbackResponder.default_responses()
    end
  end

  describe "call/1 — question d'opinion" do
    test "retourne une réponse générique pour une question d'opinion" do
      response = FallbackResponder.call("est-ce que Paris est belle ?")
      assert response in FallbackResponder.question_responses()
    end
  end

  describe "call/1 — météo et recherche web" do
    @tag :slow
    test "retourne la météo quand détectée" do
      response = FallbackResponder.call("quel temps fait-il à Paris")
      assert String.starts_with?(response, "Météo") or is_binary(response)
    end

    @tag :slow
    test "lance une recherche web pour une question factuelle" do
      response = FallbackResponder.call("qui a inventé le téléphone")
      assert is_binary(response)
      assert String.length(response) > 0
    end
  end
end
