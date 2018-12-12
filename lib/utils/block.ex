defmodule Block do
  @target 3

  def create(data, prev_hash, block_height, txns) do
    timestamp = DateTime.utc_now() |> DateTime.to_unix()

    block = %{
      :merkle_root => data,
      :timestamp => timestamp,
      :prev_hash => prev_hash,
      :hash => nil,
      :nonce => 0,
      :target => @target,
      :block_height => block_height,
      :txns => txns
    }

    if(data == "") do
      {hash, nonce} = {hash(data, prev_hash, timestamp, 0), 0}
      Map.merge(block, %{:hash => hash, :nonce => nonce})
    else
      {hash, nonce} = mine(@target, 0, block)
      Map.merge(block, %{:hash => hash, :nonce => Integer.to_string(nonce, 16)})
    end
  end

  def mine(target, nonce, block) do
    hash = hash(block.merkle_root, block.prev_hash, block.timestamp, Integer.to_string(nonce, 16))

    if(zeros(target) == hash_slice(hash, target)) do
      {hash, nonce}
    else
      nonce = nonce + 1
      mine(target, nonce, block)
    end
  end

  def hash(data, prev_hash, timestamp, nonce) do
    appended_block = "#{data}#{prev_hash}#{timestamp}#{nonce}"
    :crypto.hash(:sha256, appended_block) |> Base.encode16() |> String.downcase()
  end

  def zeros(target) do
    zeros = for _ <- 1..target, do: "0"
    zeros |> Enum.join("")
  end

  def hash_slice(hash, target) do
    String.slice(hash, 0..(target - 1))
  end
end
