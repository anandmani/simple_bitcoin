defmodule Wallet do
  @moduledoc """
    Implementing:
      - address generation
       - network wallet responsible for monitoring the blockchain to look for incoming bitcoin
  """

  def generate_key_pair, do: :crypto.generate_key(:ecdh, :secp256k1)

  def calc_address(private_key, version_bytes) do
    private_key
    |> get_public_key()
    |> hash(:sha256)
    |> hash(:ripemd160)
    |> prepend_version(version_bytes)
    |> encode()
  end

  def get_public_key(private_key) do
    private_key
    |> String.valid?()
    |> decode_key(private_key)
    |> generate_public_key()
  end

  defp decode_key(isValid, private_key) do
    case isValid do
      true -> Base.decode16!(private_key)
      false -> private_key
    end
  end

  defp generate_public_key(private_key) do
    with {public_key, _private_key} <- :crypto.generate_key(:ecdh, :secp256k1, private_key),
         do: public_key
  end

  defp hash(key, hashing_algo), do: :crypto.hash(hashing_algo, key)

  def prepend_version(public_hash, version_bytes) do
    version_bytes
    |> Kernel.<>(public_hash)
  end

  def encode(version_hash) do
    version_hash
    |> hash(:sha256)
    |> hash(:sha256)
    |> checksum()
    |> append(version_hash)
    |> Base58Enc.encode()
  end

  defp checksum(<<checksum::bytes-size(4), _::bits>>), do: checksum

  defp append(checksum, hash), do: hash <> checksum

  def get_keys() do
    {public_key, private_key} = generate_key_pair()
    signature = Signature.generate(private_key, "")
    address = calc_address(private_key, <<0x00>>)
    %{
      :private_key => private_key,
      :public_key => public_key,
      :public_key_hash => address,
      :signature => signature
    }
  end

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


#TODO:
  # def handle_call({method, methodArgs}, _from, state) do
  #   case method do
  #     :get_address ->
  #       {signature, public_key, message} = methodArgs
  #       bool = Signature.verify(public_key, signature, message)
  #       case bool do
  #         true -> {:reply, state.address, state}
  #         false -> {:reply, nil, []}
  #       end
  #   end
  # end
