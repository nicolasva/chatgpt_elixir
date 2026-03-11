defmodule Chatgpt.ChatbotFeatureTest do
  use Cabbage.Feature,
    async: false,
    file: "chatbot.feature"

  # Ces tests nécessitent CouchDB + les GenServers (AutoLearner, IntentDetector, etc.)
  # Lance-les avec : mix test --include integration test/features/
  @moduletag :integration

  # ---------------------------------------------------------------------------
  # Contexte (Background)
  # ---------------------------------------------------------------------------

  defgiven ~r/^le chatbot est initialisé$/, _, _state do
    session_id = "cucumber-#{:crypto.strong_rand_bytes(4) |> Base.encode16(case: :lower)}"
    {:ok, %{session_id: session_id}}
  end

  # ---------------------------------------------------------------------------
  # Quand / When
  # ---------------------------------------------------------------------------

  # Cabbage passe les named captures avec des clés STRING (ex: %{"message" => "..."})
  defwhen ~r/^je dis "(?<message>[^"]+)"$/, %{message: message}, state do
    response = Chatgpt.ChatService.predict(message, state.session_id)
    {:ok, %{response: response}}
  end

  # ---------------------------------------------------------------------------
  # Alors / Then
  # ---------------------------------------------------------------------------

  defthen ~r/^la réponse devrait être "(?<expected>[^"]+)"$/, %{expected: expected}, state do
    assert state.response == expected,
           "Attendu \"#{expected}\", mais reçu : \"#{state.response}\""
  end

  defthen ~r/^la réponse devrait être parmi:$/, %{table: rows}, state do
    possible = Enum.map(rows, fn [value] -> String.trim(value) end)

    assert state.response in possible,
           "Attendu une de #{inspect(possible)}, mais reçu : \"#{state.response}\""
  end

  defthen ~r/^la réponse devrait contenir "(?<substring>[^"]+)"$/, %{substring: substring}, state do
    assert String.contains?(state.response, substring),
           "Attendu que la réponse contienne \"#{substring}\", mais reçu : \"#{state.response}\""
  end

  defthen ~r/^la réponse devrait contenir un de:$/, %{table: rows}, state do
    substrings = Enum.map(rows, fn [value] -> String.trim(value) end)
    response_lower = String.downcase(state.response)

    matched = Enum.any?(substrings, fn s -> String.contains?(response_lower, String.downcase(s)) end)

    assert matched,
           "Attendu que la réponse contienne un de #{inspect(substrings)}, mais reçu : \"#{state.response}\""
  end

  defthen ~r/^la réponse devrait commencer par "(?<prefix>[^"]+)"$/, %{prefix: prefix}, state do
    assert String.starts_with?(state.response, prefix),
           "Attendu que la réponse commence par \"#{prefix}\", mais reçu : \"#{state.response}\""
  end

  defthen ~r/^la réponse ne devrait pas être vide$/, _, state do
    assert state.response != nil
    assert String.length(state.response) > 0, "La réponse ne devrait pas être vide"
  end

  defthen ~r/^la réponse devrait être une réponse positive$/, _, state do
    assert state.response in Chatgpt.FallbackResponder.positive_responses(),
           "Attendu une réponse positive, mais reçu : \"#{state.response}\""
  end

  defthen ~r/^la réponse devrait être une réponse négative$/, _, state do
    assert state.response in Chatgpt.FallbackResponder.negative_responses(),
           "Attendu une réponse négative, mais reçu : \"#{state.response}\""
  end

  defthen ~r/^la réponse devrait être une réponse de question$/, _, state do
    assert state.response in Chatgpt.FallbackResponder.question_responses(),
           "Attendu une réponse de question, mais reçu : \"#{state.response}\""
  end

  defthen ~r/^la réponse devrait être une réponse par défaut$/, _, state do
    assert state.response in Chatgpt.FallbackResponder.default_responses(),
           "Attendu une réponse par défaut, mais reçu : \"#{state.response}\""
  end
end
