defmodule Miner do
  use GenServer

  def start_link() do
    GenServer.start_link(__MODULE__, :ok, [])
  end

  def transaction_poll(server) do
    GenServer.cast(server, {:transaction_poll, {}})
  end

  def get_blockchain(server) do
    GenServer.cast(server, {:get_blockchain, {}})
  end

  def set_keys(server) do
    GenServer.cast(server, {:set_keys, {}})
  end

  def register(server) do
    GenServer.cast(server, {:register, {}})
  end

  def update_balance(server) do
    GenServer.cast(server, {:update_balance, {}})
  end

  @doc "Unsolicited Block Push"
  def receive_block(server, blockchain) do
    # IO.puts("received block"); IO.inspect(block);
    GenServer.cast(server, {:receive_block, {blockchain}})
    GenServer.cast(server, {:update_balance, {}})
  end

  @doc "Send satoshis to destination node"
  def send_satoshi(server, value, public_key_hash) do
    GenServer.cast(server, {:send_satoshi, {value, public_key_hash}})
  end

  def init(:ok) do
    {:ok,
     %{
       :blockchain => [],
       :utxos => [
        #  {20, %{output_index: 0, tx_hash: "a"}},
        #  {5, %{output_index: 0, tx_hash: "b"}},
        #  {10, %{output_index: 0, tx_hash: "c"}},
        #  {10, %{output_index: 0, tx_hash: "d"}}
      ],
      :private_key => nil,
      :public_key => nil,
      :public_key_hash => nil
     }}
  end

  def create_block(transactions, state) do
    transaction_hashes = transactions |> Enum.map(fn transaction -> transaction.hash end)
    merkle_root = create_merkle_tree(transaction_hashes)
    last_block = List.last(Bitcoind.get_blockchain(:bitcoind))
    prev_hash = last_block.hash
    block_height = last_block.block_height + 1
    transactions = [create_coinbase_transaction(500, state)] ++ transactions
    block = Block.create(merkle_root, prev_hash, block_height, transactions)
    # IO.puts("miner utxos")
    # IO.inspect(state.utxos)
    Bitcoind.add_block(:bitcoind, block)
    send_satoshi(state)
  end

  def create_merkle_tree(transaction_hashes) do
    transaction_hashes =
      transaction_hashes
      |> Enum.map(fn transaction_hash -> hash(transaction_hash) end)
      |> Enum.chunk_every(2)
      |> Enum.map(fn pair -> List.first(pair) <> List.last(pair) end)

    if(Enum.count(transaction_hashes) == 1) do
      hash(List.first(transaction_hashes))
    else
      create_merkle_tree(transaction_hashes)
    end
  end

  def hash(tx_id) do
    :crypto.hash(:sha256, tx_id) |> Base.encode16()
  end

  def create_coinbase_transaction(value, state) do
    transaction_outputs = [Transaction.generate_a_tx_out(value, state.public_key_hash)]
    Participant.create_tx_from_inputs_and_outputs([], transaction_outputs)
  end

  def send_satoshi(state) do
    value = :rand.uniform(100)
    balance = Enum.reduce(state.utxos, 0, fn ({k, _v}, acc) -> k + acc end)
    if (!Enum.empty?(state.utxos)) do
      receiver = String.to_atom("participant_" <>  Integer.to_string(:rand.uniform(100)))
      IO.puts("balance(miner_1)  = #{balance}")
      IO.puts("Sending #{value} satoshis from miner_1 to #{receiver}")
      send_satoshi(self(), value, Participant.get_public_key(receiver))
    end
  end

  def handle_cast({method, methodArgs}, state) do
    case method do
      :transaction_poll ->
        get_transactions()
        {:noreply, state}

      :get_blockchain ->
        blockchain = Bitcoind.get_blockchain(:bitcoind)
        {:noreply, Map.merge(state, %{:blockchain => blockchain})}

      :set_keys ->
        participant_key_map = Wallet.get_keys()
        {:noreply, Map.merge(state, participant_key_map)}

      :register ->
        DnsSeed.register_participant(:dns_seed, self())
        {:noreply, state}

      :update_balance ->
        # TODO: send pubkeyhash
        new_utxos = Wallet.check_block(List.last(state.blockchain), state.public_key_hash)
        new_state = update_in(state[:utxos], fn utxos -> utxos ++ new_utxos end)
        # IO.inspect(new_state)
        {:noreply, new_state}

      :receive_block ->
        {blockchain} = methodArgs
        {:noreply, Map.merge(state, %{:blockchain => blockchain})}

      :send_satoshi ->
        {value, public_key_hash} = methodArgs
        new_state = Participant.handle_send_satoshi(state, value, public_key_hash)
        {:noreply, new_state}
    end
  end

  defp get_transactions() do
    Process.send_after(self(), :get_transactions, 5 * 1000)
  end

  def handle_info(:get_transactions, state) do
    transactions = Bitcoind.get_transactions(:bitcoind)
    if(!Enum.empty?(transactions)) do
      create_block(transactions, state)
      # IO.puts("BLOCKCHAIN")
      # IO.inspect(blockchain)
    end
    get_transactions()
    {:noreply, state}
  end
end
