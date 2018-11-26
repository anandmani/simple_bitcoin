defmodule Bitcoind do
  use GenServer

  def start_link do
    {:ok, bitcoind_pid} = GenServer.start_link(__MODULE__, :ok, [])
    Process.register(bitcoind_pid, :bitcoind)
    create_genesis(:bitcoind)
  end

  def new_transaction(server, trans_id) do
    GenServer.cast(server, {:new_transaction, trans_id})
  end

  def get_trans_list(server) do
    GenServer.call(server, {:get_trans_list, nil})
  end

  def create_genesis(server) do
    GenServer.cast(server, {:create_genesis, nil})
  end

  def get_blockchain(server) do
    GenServer.call(server, {:get_blockchain, nil})
  end

  def add_block(server, block) do
    GenServer.call(server, {:add_block, block})
  end

  def init(:ok) do
    {:ok, 
      %{
        :trans_list => [],
        :blockchain => []
      }
    }
  end

  def handle_cast({method, args}, state) do
    case method do
      :new_transaction ->
        trans_id = args
        {:noreply, Map.update!(state, :trans_list, fn _ -> Map.get(state, :trans_list) ++ [trans_id] end)}
      
      :create_genesis ->
        genesis_block = Block.create("Genesis")
        {:noreply, Map.update!(state, :blockchain, fn _ -> Map.get(state, :blockchain) ++ [genesis_block] end)}
    end 
  end

  def handle_call({method,methodArgs}, _from, state) do
    case method do
      :get_trans_list ->
        trans_list = state.trans_list
        {:reply, trans_list, Map.update!(state, :trans_list, fn _-> [] end)}

      :get_blockchain ->
        {:reply, state.blockchain, state}

      :add_block ->
        block = methodArgs
        blockchain = state.blockchain ++ [block]
        case verify_block(state, Enum.reverse(blockchain)) do
          true -> 
            Enum.map(1..1, fn x -> Miner.blockchain_broadcast(String.to_atom("miner" <> Integer.to_string(x)), blockchain) end)
            {:reply, true, Map.update!(state, :blockchain, fn _ -> blockchain end)}
          false -> {:reply, false, state}
        end 
    end
  end

  def verify_block(state, blockchain) do
    if(Enum.count(blockchain) == 1) do 
      true
    else  
      case hd(blockchain).prev_hash == List.first(tl(blockchain)).hash do
        true -> verify_block(state, tl(blockchain))
        false -> false
      end
    end
  end
end