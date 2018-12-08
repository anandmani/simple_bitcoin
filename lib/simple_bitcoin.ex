defmodule SimpleBitcoin do
  # TODO:
  # username = Enum.map(1..numParticipants, fn x -> IO.gets("User #{x}: ") |> String.trim end)
  # Enum.map(username, fn username -> Wallet.start_link(username) end)

  def start(value \\ 10) do
    participant_zero_keys = Wallet.get_keys()
    participant_one_keys = Wallet.get_keys()

    # _dummy_block = %{
    #   :txns => [
    #     %{
    #       :hash => "dummy",
    #       :tx_out => [
    #         %{
    #           :value => 1,
    #           :pk_script => "OP_HASH160 1APjUvMJUYdYthWBEAtpJgQyeWMBMqcySu OP_EQUALVERIFY"
    #         }
    #       ]
    #     }
    #   ]
    # }

    {:ok, dns_seed_pid} = DnsSeed.start_link([])
    Process.register(dns_seed_pid, :dns_seed)

    {:ok, bitcoind_pid} = Bitcoind.start_link([])
    Process.register(bitcoind_pid, :bitcoind)
    Bitcoind.generate_genesis_block(:bitcoind, participant_zero_keys.public_key_hash)

    # Start Miner
    Enum.map(1..1, fn x -> Miner.start_link("miner" <> Integer.to_string(x)) end)

    {:ok, pid} = Participant.start_link([])
    Process.register(pid, :participant_a)
    Participant.register(:participant_a)
    Participant.init_blockchain(:participant_a)
    Participant.set_keys(:participant_a, participant_zero_keys)
    Participant.update_balance(:participant_a)
    # Participant.inspect(:participant_a)

    {:ok, pid} = Participant.start_link([])
    Process.register(pid, :participant_b)
    Participant.register(:participant_b)
    Participant.init_blockchain(:participant_b)
    Participant.set_keys(:participant_b, participant_one_keys)
    Participant.update_balance(:participant_b)
    # Participant.inspect(:participant_b)

    IO.puts("Sending 10 satoshis from Node a to Node b")
    Participant.send_satoshi(:participant_a, value, participant_one_keys.public_key_hash)
  end
end

# TODO
# Code genesis block into participant blockchain
# Write testcase for A to send B 10 coins
# Miner polls bitcoind for transactions (Implement mining - polling, mining, merkle tree, coinbase tnx, block broadcast)
# Miner mines block and messages A and B about it (Implement participant to recive block as message)
