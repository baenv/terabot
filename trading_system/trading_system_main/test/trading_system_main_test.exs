defmodule TradingSystemMainTest do
  use ExUnit.Case
  doctest TradingSystemMain

  test "greets the world" do
    assert TradingSystemMain.hello() == :world
  end
end
