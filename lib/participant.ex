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
  def get_blockchain(server) do
    GenServer.cast(server, {:get_blockchain, {}})
  end

  @doc "Set hardcoded keys. Used in the case of genesis block, to set keys for first participant"
  def set_keys(server) do
    GenServer.cast(server, {:set_keys, {}})
  end

  def   get_public_key(server) do
    GenServer.call(server, {:get_public_key})
  end

  def inspect(server) do
    GenServer.cast(server, {:inspect, {}})
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

  def send_satoshi_init(server) do
    GenServer.cast(server, {:send_satoshi_init, {}})
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
    tx
  end

  def handle_send_satoshi(state, value, public_key_hash) do
    {reduced_sum, reduced_index} = reduce_utxos(state[:utxos], value)
    cond do
      reduced_sum < value ->
        # IO.puts("Insufficient balance")
        state

      true ->
        utxos_needed = Enum.take(state[:utxos], reduced_index + 1)
        transaction_inputs = get_transaction_inputs_from_utxos(utxos_needed, state.public_key)
        change = reduced_sum - value
        transaction_outputs = cond do
          change == 0 ->
            [
              Transaction.generate_a_tx_out(value, public_key_hash)
            ]
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

      :get_blockchain ->
        blockchain = Bitcoind.get_blockchain(:bitcoind)
        {:noreply, Map.merge(state, %{:blockchain => blockchain})}

      :inspect ->
        # IO.inspect(state.utxos)
        {:noreply, state}

      :update_balance ->
        # TODO: send pubkeyhash
        new_utxos = Wallet.check_block(List.last(state.blockchain), state.public_key_hash)
        new_state = update_in(state[:utxos], fn utxos -> utxos ++ new_utxos end)
        # IO.inspect(new_state)
        {:noreply, new_state}

      :set_keys ->
        participant_key_map = Wallet.get_keys()
        {:noreply, Map.merge(state, participant_key_map)}

      :receive_block ->
        {blockchain} = methodArgs
        {:noreply, Map.merge(state, %{:blockchain => blockchain})}

      :send_satoshi ->
        {value, public_key_hash} = methodArgs
        new_state = handle_send_satoshi(state, value, public_key_hash)
        {:noreply, new_state}

      :send_satoshi_init ->
        send_satoshi()
        {:noreply, state}
    end
  end

  def handle_call({method}, _from, state) do
    case method do
      :get_public_key ->
        {:reply, state.public_key_hash, state}
    end
  end

  def send_satoshi() do
    Process.send_after(self(), :send_satoshi, 2 * 1000)
  end

  def handle_info(:send_satoshi, state) do
    # sender = elem(List.first(Process.info(self())), 1)
    # IO.inspect(sender)
    # IO.inspect(state.utxos)
    if (!Enum.empty?(state.utxos)) do
      value = :rand.uniform(50)
      balance = Enum.reduce(state.utxos, 0, fn ({k, _v}, acc) -> k + acc end)
      receiver = String.to_atom("participant_" <>  Integer.to_string(:rand.uniform(100)))
      sender = elem(List.first(Process.info(self())), 1)
      if(sender != receiver) do
        IO.puts("balance(#{sender})  = #{balance}")
        IO.puts("Sending #{value} satoshis from #{sender} to #{receiver}")
        send_satoshi(self(), value, get_public_key(receiver))
      end
    end
    send_satoshi()
    {:noreply, state}
  end

end
