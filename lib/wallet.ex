defmodule Wallet do
  @moduledoc """
    Implementing the network wallet responsible for monitoring the blockchain to look for incoming bitcoin
  """
  @doc """
    Checks if tx_out was made to calling node.
    Returns bool
  """
  def verify_payee(out, public_key_hash) do
    ls = String.split(out.pk_script)
    prev_index = Enum.find_index(ls, fn x -> x == "OP_HASH160" end)
    Enum.at(ls, prev_index + 1) == public_key_hash
  end

  @doc """
    Check txn for any output made to calling node.
    Returns tuple {value, %{:tx_hash, :output_index}}
  """
  def check_tx(tx, public_key_hash) do
    tx.tx_out
    |> Enum.with_index()
    |> Enum.reduce(nil, fn curr, acc ->
      out = elem(curr, 0)
      index = elem(curr, 1)
      ret = verify_payee(out, public_key_hash)

      cond do
        ret == true ->
          {
            out.value,
            %{
              :tx_hash => tx.hash,
              :output_index => index
            }
          }

        true ->
          acc
      end
    end)
  end

  @doc """
    Check the block for any payments made to calling node.
    Returns list of tuples: [{value, %{tx_hash, output_index}}]
    eg.
    [
      {5000000000, %{output_index: 0, tx_hash: "abcd"}},
      {1, %{output_index: 0, tx_hash: "dummy"}}
    ]
  """
  def check_block(block, public_key_hash) do
    Enum.reduce(block.txns, [], fn curr, acc ->
      ret = check_tx(curr, public_key_hash)

      cond do
        ret != nil ->
          [ret | acc]

        true ->
          acc
      end
    end)
  end
end

# Sample Input:
# block = %{
#   :txns => [
#     %{
#       :hash => "abcd",
#       :tx_out => [
#         %{
#           :value => 150,
#           :pk_script => "OP_HASH160 hash1 OP_EQUALVERIFY"
#         },
#         %{
#           :value => 100,
#           :pk_script => "OP_HASH160 hash2 OP_EQUALVERIFY"
#         },
#       ],
#     },
#     %{
#       :hash => "efgh",
#       :tx_out => [
#         %{
#           :value => 50,
#           :pk_script => "OP_HASH160 hash1 OP_EQUALVERIFY"
#         },
#       ],
#     }
#   ]
# }

