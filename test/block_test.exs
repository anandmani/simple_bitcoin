defmodule BlockTest do
  use ExUnit.Case, async: true

  test "Check leading zeros in a block hash is equal to target" do
    block = Block.create("hash", "prev_hash", 1, "transaction_hash") 
    assert String.slice(block.hash, 0..(block.target-1)) == "000"
  end
end
