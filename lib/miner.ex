defmodule Miner do
  use GenServer

  def start_link(args) do
    name = String.to_atom(args)
    {:ok, pid} = GenServer.start_link(__MODULE__, args, [])
    Process.register(pid, name)
    transaction_poll(name)
  end

  def transaction_poll(server) do
    GenServer.cast(server, {:transaction_poll, nil})
  end

  def init(username) do
    {:ok,
     %{
       :name => username
     }}
  end

  def handle_cast({method, _methodArgs}, state) do
    case method do
      :transaction_poll ->
        get_transactions()
        {:noreply, state}
    end
  end

  defp get_transactions() do
    Process.send_after(self(), :get_transactions, 5 * 1000)
  end

  def handle_info(:get_transactions, state) do
    transactions = Bitcoind.get_transactions(:bitcoind)

    if(!Enum.empty?(transactions)) do
      create_block(transactions, state)
    end

    get_transactions()
    {:noreply, state}
  end

  def create_block(transactions, _state) do
    transaction_hashes = transactions |> Enum.map(fn transaction -> transaction.hash end)
    merkle_root = create_merkle_tree(transaction_hashes)
    last_block = List.last(Bitcoind.get_blockchain(:bitcoind))
    prev_hash = last_block.hash
    block_height = last_block.block_height + 1
    block = Block.create(merkle_root, prev_hash, block_height, transactions)

    Bitcoind.add_block(:bitcoind, block)
    Participant.receive_block(:participant_a, block)
    Participant.receive_block(:participant_b, block)

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
end
