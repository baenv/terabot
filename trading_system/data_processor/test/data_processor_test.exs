defmodule DataProcessorTest do
  use ExUnit.Case
  doctest DataProcessor

  test "greets the world" do
    assert DataProcessor.hello() == :world
  end
end
