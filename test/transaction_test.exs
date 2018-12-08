defmodule TransactionTest do
  use ExUnit.Case, async: true

  setup do
    tx = %{
      tx_in: [
        %{
          previous_output: %{hash: "dummy_hash", index: 0},
          signature_script: "0459DBCB2CD20BD058F9A1A7C512A525C31BAAA28C79FE81BE096B2707D5718F7E0514FDFB1F4F09393020DFF4F1DA4C0A4317D2CAFC311C152D2AD2F7D1C8638A"
        }
      ],
      tx_out: [
        %{
          pk_script: "OP_HASH160 18UF6X7y9WkaJox5tJhCQ5HR7NCS8KzymR OP_EQUALVERIFY",
          value: 10
        },
        %{
          pk_script: "OP_HASH160 1JXun8psUhEEkbPSeBHMyx54Eaj2ev3WYj OP_EQUALVERIFY",
          value: 90
        }
      ]
    }
    {:ok, tx: tx}
  end

  test "Compute hash of a transaction", context do
    assert Transaction.compute_hash(context[:tx]) == "A519AF95265711511EDD32C879546E4EE79C2B1AB49FF3475CD3C8B59B1B606C"
  end
end
