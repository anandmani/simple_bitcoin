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

  def blockchain_broadcast(server, blockchain) do
    GenServer.cast(server, {:blockchain_broadcast, blockchain})
  end

  def init(username) do
    {:ok, 
      %{
        :blockchain => nil,
        :name => username
      }
    }
  end

  def handle_cast({method, methodArgs}, state) do
    case method do
      :transaction_poll ->
        get_trans_list()
        {:noreply, state}
      
      :blockchain_broadcast ->
        blockchain = methodArgs
        {:noreply, Map.merge(state, %{:blockchain => blockchain})}
    end
  end

  defp get_trans_list() do
    Process.send_after(self(), :get_trans_list, 5 * 1000)
  end

  def handle_info(:get_trans_list, state) do
    trans_list = Bitcoind.get_trans_list(:bitcoind)
    if(!Enum.empty?(trans_list)) do
      create_block(trans_list, state)
    end
    IO.inspect(trans_list)
    IO.puts("bitcoind")
    IO.inspect(Bitcoind.get_blockchain(:bitcoind))
    IO.puts("state")
    IO.inspect(state.blockchain)
    get_trans_list()
    {:noreply, state}
  end

  def create_block(trans_list, state) do
    merkle_root = create_merkle_tree(trans_list)
    last_block = List.last(Bitcoind.get_blockchain(:bitcoind)) 
    prev_hash = last_block.hash
    block_height = last_block.block_height + 1
    block = Block.create(merkle_root, prev_hash, block_height, state.name)
    case Bitcoind.add_block(:bitcoind, block) do
      true -> block
      false -> nil
    end 
  end

  def create_merkle_tree(trans_list) do
    trans_list = 
    trans_list
    |> Enum.map(fn tx_id -> hash(tx_id) end) 
    |> Enum.chunk_every(2) 
    |> Enum.map(fn pair -> List.first(pair) <> List.last(pair) end)

    if(Enum.count(trans_list) == 1) do
      hash(List.first(trans_list))
    else
      create_merkle_tree(trans_list)
    end
  end

  def hash(tx_id) do
    :crypto.hash(:sha256, tx_id) |> Base.encode16()
  end
end