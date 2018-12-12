defmodule SimpleBitcoin do
  # TODO:
  # username = Enum.map(1..numParticipants, fn x -> IO.gets("User #{x}: ") |> String.trim end)
  # Enum.map(username, fn username -> Wallet.start_link(username) end)

  def start() do

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

    # Start participants
    start_participant = fn x ->
      name = String.to_atom("participant_"<>Integer.to_string(x))
      {:ok, pid} = Participant.start_link([])
      Process.register(pid, name)
      Participant.register(name)
      Participant.set_keys(name)
      if (name == :participant_1) do
        IO.puts("Creating genesis")
        Bitcoind.generate_genesis_block(:bitcoind, Participant.get_public_key(name))
      end
      Participant.get_blockchain(name)
      Participant.update_balance(name)
      Participant.send_satoshi_init(name)
    end
    Enum.map(1..100, start_participant)

    # Start Miner
    start_miner = fn x ->
      name = String.to_atom("miner" <> Integer.to_string(x))
      {:ok, pid} = Miner.start_link()
      Process.register(pid, name)
      Miner.register(name)
      Miner.transaction_poll(name)
      Miner.get_blockchain(name)
      # Miner.update_balance(name)
      Miner.set_keys(name)
    end
    Enum.map(1..1, start_miner)

  end
end

# TODO
# Code genesis block into participant blockchain
# Write testcase for A to send B 10 coins
# Miner polls bitcoind for transactions (Implement mining - polling, mining, merkle tree, coinbase tnx, block broadcast)
# Miner mines block and messages A and B about it (Implement participant to recive block as message)
