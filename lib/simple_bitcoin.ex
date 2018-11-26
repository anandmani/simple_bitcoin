defmodule SimpleBitcoin do
  def start do

    #TODO: Hardcoding here. Generate these after merging code
    #TODO: need to hardcode both the addresses? Easier to send money then

    participant_zero_keys =  %{
      :private_key => "dummy",
      :public_key => "dummy",
      :public_key_hash => "1APjUvMJUYdYthWBEAtpJgQyeWMBMqcySu"
    }

    participant_one_keys =  %{
      :private_key => "dummy",
      :public_key => "dummy",
      :public_key_hash => "qwertyuiop"
    }

    _dummy_block = %{
      :txns => [
        %{
          :hash => "dummy",
          :tx_out => [
            %{
              :value => 1,
              :pk_script => "OP_HASH160 1APjUvMJUYdYthWBEAtpJgQyeWMBMqcySu OP_EQUALVERIFY"
            }
          ]
        }
      ]
    }

    {:ok, dns_seed_pid} = DnsSeed.start_link([])
    Process.register(dns_seed_pid, :dns_seed)

    {:ok, bitcoind_pid} = Bitcoind.start_link([])
    Process.register(bitcoind_pid, :bitcoind)
    Bitcoind.generate_genesis_block(:bitcoind, participant_zero_keys.public_key_hash)

    #Start Miner

    {:ok, pid} = Participant.start_link([])
    Process.register(pid, :participant_a)
    Participant.register(:participant_a)
    Participant.init_blockchain(:participant_a)
    Participant.set_keys(:participant_a, participant_zero_keys)
    Participant.update_balance(:participant_a)
    # Participant.receive_block(:participant_a, dummy_block)
    Participant.inspect(:participant_a)

    {:ok, pid} = Participant.start_link([])
    Process.register(pid, :participant_b)
    Participant.register(:participant_b)
    Participant.init_blockchain(:participant_b)
    Participant.set_keys(:participant_b, participant_one_keys)
    Participant.update_balance(:participant_b)
    # Participant.receive_block(:participant_a, dummy_block)
    Participant.inspect(:participant_b)

    Participant.send_satoshi(:participant_a, 10, "qwertyuiop")

  end
end

# TODO
# Code genesis block into participant blockchain
# Write testcase for A to send B 10 coins
# Miner polls bitcoind for transactions (Implement mining - polling, mining, merkle tree, coinbase tnx, block broadcast)
# Miner mines block and messages A and B about it (Implement participant to recive block as message)
