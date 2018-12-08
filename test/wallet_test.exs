defmodule WalletTest do
  use ExUnit.Case, async: true

  setup do
    tx = %{
      hash: "78C46381D65F5901F530C1F3CC52B30CD7142C6F489721AEE34BDDA882373414",
      tx_in: [
        %{
          previous_output: %{hash: "dummy_hash", index: 0},
          signature_script: "04E29F8647DAC1DD007D5BE6BA1C4D293821C3058F54292902FA1E3F1789D0CD7BC2117BC408B969763A03F82892FC5BDD2DD02EB8B4EE5E6C080874545BF45E32"
        }
      ],
      tx_out: [
        %{
          pk_script: "OP_HASH160 18QpPjxwkmj4TSoGmDXa6BBE9SzpTiZfW5 OP_EQUALVERIFY",
          value: 10
        },
        %{
          pk_script: "OP_HASH160 1ESaD2So4VAGUcyJ3GvGnAoAjPXaeM8xfs OP_EQUALVERIFY",
          value: 90
        }
      ]
    }

    utxo = { 90,
      %{
        output_index: 1,
        tx_hash: "78C46381D65F5901F530C1F3CC52B30CD7142C6F489721AEE34BDDA882373414"
      }
    }

    public_key_hash = "1ESaD2So4VAGUcyJ3GvGnAoAjPXaeM8xfs"

    {
      :ok,
      tx: tx,
      utxo: utxo,
      public_key_hash: public_key_hash
    }
  end

  test "Obtain utxo from a new transaction added to the blockchain", context do
    assert Wallet.check_tx(context[:tx], context[:public_key_hash]) == context[:utxo]
  end

  test "Check if a private key creates same address everytime" do
    key_map = Wallet.get_keys()
    assert key_map.public_key_hash == Wallet.calc_address(key_map.private_key, <<0x00>>)
  end

end
