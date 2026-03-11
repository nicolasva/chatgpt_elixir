defmodule Chatgpt.UserMessageTest do
  use ExUnit.Case, async: true

  alias Chatgpt.UserMessage

  describe "question?/1" do
    test "détecte un point d'interrogation" do
      assert UserMessage.question?(UserMessage.new("tu vas bien ?", nil)) == true
    end

    test "détecte un mot interrogatif (qui)" do
      assert UserMessage.question?(UserMessage.new("qui est le président", nil)) == true
    end

    test "détecte un mot interrogatif (comment)" do
      assert UserMessage.question?(UserMessage.new("comment ça marche", nil)) == true
    end

    test "détecte un mot interrogatif (où)" do
      assert UserMessage.question?(UserMessage.new("où est la gare", nil)) == true
    end

    test "détecte un mot interrogatif (pourquoi)" do
      assert UserMessage.question?(UserMessage.new("pourquoi le ciel est bleu", nil)) == true
    end

    test "ne détecte pas une affirmation" do
      assert UserMessage.question?(UserMessage.new("je suis content", nil)) == false
    end

    test "ne détecte pas un salut" do
      assert UserMessage.question?(UserMessage.new("bonjour", nil)) == false
    end
  end
end
