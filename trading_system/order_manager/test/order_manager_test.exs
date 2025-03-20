defmodule OrderManagerTest do
  use ExUnit.Case
  doctest OrderManager

  test "greets the world" do
    assert OrderManager.hello() == :world
  end
end
