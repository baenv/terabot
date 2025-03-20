defmodule DecisionEngineTest do
  use ExUnit.Case
  doctest DecisionEngine

  test "greets the world" do
    assert DecisionEngine.hello() == :world
  end
end
