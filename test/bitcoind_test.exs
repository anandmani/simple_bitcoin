defmodule BitcoindTest do
  use ExUnit.Case, async: true

  test "Verify that the prev_hash of each block in a blockchain is equal to the hash of the previous block" do
    blockchain = [%{:hash => "a", :prev_hash => "-"}, %{:hash => "b", :prev_hash => "a"},
                  %{:hash => "c", :prev_hash => "b"}, %{:hash => "d", :prev_hash => "c"}]
    assert Bitcoind.verify_block(Enum.reverse(blockchain)) == true
  end
end
