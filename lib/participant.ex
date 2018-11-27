# implement a receive message function
# Types of messages:
# inv = the miner, acting as a standard relay node, sends an inv message to each of its peers
# getData = Each blocks-first (BF) peer that wants the block replies with a getdata message requesting the full block.

defmodule Participant do
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  # Get pvt key, pub key
  # make a transaction
  # send transaction to bitcoind

  @doc "Register with dns_seed"
  def register(server) do
    GenServer.cast(server, {:register, {}})
  end

  @doc "Initialize local blockchain with genesis block"
  def init_blockchain(server) do
    GenServer.cast(server, {:init_blockchain, {}})
  end

  @doc "Set hardcoded keys. Used in the case of genesis block, to set keys for first participant"
  def set_keys(server, keys_map) do
    GenServer.cast(server, {:set_keys, {keys_map}})
  end

  @doc "Generate Private, Public keys from wallet"
  def get_keys(server) do
    GenServer.cast(server, {:get_keys, {}})
  end

  def inspect(server) do
    GenServer.cast(server, {:inspect, {}})
  end

  def update_balance(server) do
    GenServer.cast(server, {:update_balance, {}})
  end

  @doc "Unsolicited Block Push"
  def receive_block(server, block) do
    # IO.puts("received block"); IO.inspect(block);
    GenServer.cast(server, {:receive_block, {block}})
    GenServer.cast(server, {:update_balance, {}})
  end

  @doc "Send satoshis to destination node"
  def send_satoshi(server, value, public_key_hash) do
    GenServer.cast(server, {:send_satoshi, {value, public_key_hash}})
  end

  ## Server Callbacks
  def init(:ok) do
    {:ok,
     %{
       # Stored as a stack. Last block at index 0
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
       # TODO:  :signature => nil
     }}
  end

  def handle_get_keys(state) do
    cond do
      state.private_key != nil ->
        %{}

      true ->
        # TODO: Hardcoding now. Call wallet to generate keys
        %{
          :private_key => "dummy",
          :public_key => "dummy",
          :public_key_hash => "dummy"
        }
    end
  end

  @doc """
    Sequentially traverses through the utxos and checks how many utxos are required to pay 'value'
    returns {sum_of_first_n_utxo | index_of_nth_utxo}
    If not all utxos are needed, the sequential traversal is broken.
    If utxos balance < value, returns {sum_of_all_utxos, count_utxos - 1}
    Need to make sum < value outside f
    utxos = [
      {5000000000, %{output_index: 0, tx_hash: "abcd"}}
    ]
    Enum.with_index = [
      {{5000000000, %{output_index: 0, tx_hash: "abcd"}}, 0}
    ]
  """
  def reduce_utxos(utxos, value) do
    utxos
    |> Enum.with_index()
    |> Enum.reduce_while({0, -1}, fn curr, acc ->
      index = elem(curr, 1)
      utxo = elem(curr, 0)
      sum = elem(acc, 0) + elem(utxo, 0)
      if sum < value, do: {:cont, {sum, index}}, else: {:halt, {sum, index}}
    end)
  end

  @doc "Converts list of required utxos to list of transaction_inputs "
  def get_transaction_inputs_from_utxos(utxos, public_key) do
    utxos
    |> Enum.map(fn utxo ->
      utxo_output_hash = elem(utxo, 1).tx_hash
      utxo_output_index = elem(utxo, 1).output_index
      Transaction.generate_a_tx_in(utxo_output_hash, utxo_output_index, public_key)
    end)
  end

  def create_tx_from_inputs_and_outputs(transaction_inputs, transaction_outputs) do
    tx = %{
      :tx_in => transaction_inputs,
      :tx_out => transaction_outputs
    }

    tx = Transaction.add_hash(tx)
    # IO.puts("Transaction created")
    # IO.inspect(tx)
    tx
  end

  def handle_send_satoshi(state, value, public_key_hash) do
    {reduced_sum, reduced_index} = reduce_utxos(state[:utxos], value)

    cond do
      reduced_sum < value ->
        IO.puts("Insufficient balance")
        state

      true ->
        utxos_needed = Enum.take(state[:utxos], reduced_index + 1)
        transaction_inputs = get_transaction_inputs_from_utxos(utxos_needed, state.public_key)
        change = reduced_sum - value
        transaction_outputs = cond do
          change == 0 ->
            Transaction.generate_a_tx_out(value, public_key_hash)
          true ->
            [
              Transaction.generate_a_tx_out(value, public_key_hash),
              Transaction.generate_a_tx_out(change, state.public_key_hash)
            ]
        end

        tx = create_tx_from_inputs_and_outputs(transaction_inputs, transaction_outputs)
        Bitcoind.receive_transaction(:bitcoind, tx)

        unspent_utxos =
          state[:utxos] |> Enum.take(-1 * (Enum.count(state[:utxos]) - 1 - reduced_index))

        # IO.puts("Unspent satoshis")
        # IO.inspect(unspent_utxos)
        Map.merge(state, %{:utxos => unspent_utxos})
    end
  end

  def handle_cast({method, methodArgs}, state) do
    case method do
      :register ->
        DnsSeed.register_participant(:dns_seed, self())
        {:noreply, state}

      :init_blockchain ->
        genesis_block = Bitcoind.get_genesis_block(:bitcoind)
        {:noreply, Map.merge(state, %{:blockchain => [genesis_block]})}

      :inspect ->
        IO.inspect(state.utxos)
        {:noreply, state}

      :update_balance ->
        # TODO: send pubkeyhash
        new_utxos = Wallet.check_block(Enum.at(state.blockchain, 0), state.public_key_hash)
        new_state = update_in(state[:utxos], fn utxos -> utxos ++ new_utxos end)
        IO.puts "updated balance"; IO.inspect(new_state)
        {:noreply, new_state}

      :get_keys ->
        # TODO: Merge code and code this
        keys_map = handle_get_keys(state)
        {:noreply, Map.merge(state, keys_map)}

      :set_keys ->
        {keys_map} = methodArgs
        {:noreply, Map.merge(state, keys_map)}

      :receive_block ->
        {block} = methodArgs
        new_state = update_in(state[:blockchain], fn blockchain -> [block] ++ blockchain end)
        {:noreply, new_state}

      :send_satoshi ->
        {value, public_key_hash} = methodArgs
        new_state = handle_send_satoshi(state, value, public_key_hash)
        {:noreply, new_state}
    end
  end
end
