defmodule SimpleBitcoinTest do
  use ExUnit.Case
  doctest SimpleBitcoin

  test "greets the world" do
    assert SimpleBitcoin.hello() == :world
  end
end
