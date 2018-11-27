# Sample for A:
# Private Key:
# Public Key:
# Public Key hash:
# Base58encoded:

# #To confirm:
# #It says a tx can have multiple i/p and o/p.
# #Does this mean, Alice can aggregate multiple UTXO and pay Bob and Charlie with one tx?

defmodule Transaction do
  @moduledoc """

  # Commented fields are ignored for our simple implementation

  tx = %{
    :hash
    # :version,
    #:tx_in_count,
    :tx_in => [],
    #:tx_out_count,
    :tx_out => [],
    # :lock_time
  }

  #non-coinbase input
  tx_in = %{
    :previous_output => %{
      :hash,
      :index
    },
    # :script_bytes,
    :signature_script #String containing public_key and signature. Ignore signature?
    # :sequence
  }

  #non-coinbase output
  tx_out= %{
    :value,
    # :pk_scripts_bytes,
    # :pk_script = OP_DUP OP_HASH160 <PubkeyHash> OP_EQUALVERIFY OP_CHECKSIG
    :pk_script = OP_HASH160 <PubkeyHash> OP_EQUALVERIFY #Modified due to omission of signature from :signature_script
  }

  #coinbase tx
  %{
    hash:
    #tx_in_count: 1,
    tx_in: [
      %{
        :hash => 32 bit null, #replacement for previous_output.hash
        :index => 0xffffffff, #replacement for previous_output.index
        :script_bytes, #ignore
        :height, #ignore
        :coinbase_script => #arbit data,
        :sequence #ingore
      }
    ],
    #tx_out_count: 1,
    tx_out: [
      %{
        :value => 25BTC in satoshi,
        :pk_scripts_bytes, #Ignore
        :pk_script
      }
    ]
  }
  """

  @hash_fields [:tx_in, :tx_out]

  @doc " encodes the tx to JSON -> hashed using sha256 -> encoded to hexa "
  def compute_hash(tx) do
    binary =
      Map.take(tx, @hash_fields)
      |> Poison.encode!()

    :crypto.hash(:sha256, binary) |> Base.encode16()
  end

  @doc "Add hash field to tx"
  def add_hash(tx) do
    Map.put(tx, :hash, compute_hash(tx))
  end

  def generate_a_tx_in(output_hash, output_index, public_key) do
    %{
      :previous_output => %{
        :hash => output_hash,
        :index => output_index
      },
      # String containing public_key and signature. Ignore signature?
      :signature_script => Base.encode16(public_key)  #Remember to decode16 when verifying signature in pubkey script
    }
  end

  def generate_a_tx_out(value, pub_key_hash) do
    %{
      :value => value,
      :pk_script => "OP_HASH160 #{pub_key_hash} OP_EQUALVERIFY"
    }
  end
end

# TODO:

# Figure out coinbase tx
# Add coinbase input

# Add sample tx_in, tx_out
