defmodule Bitcoind do
  use GenServer

  def get_transactions(server) do
    GenServer.call(server, {:get_transactions, nil})
  end

  def get_blockchain(server) do
    GenServer.call(server, {:get_blockchain, nil})
  end

  def add_block(server, block) do
    GenServer.call(server, {:add_block, block})
  end

  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  @doc """
    Generates a genesis block that pays pubkeyhash 100 satoshi
  """
  def generate_genesis_block(server, pubkeyhash) do
    GenServer.cast(server, {:generate_genesis_block, {pubkeyhash}})
  end

  @doc """
    Return genesis block to calling node
  """
  def get_genesis_block(server) do
    GenServer.call(server, {:get_genesis_block, {}})
  end

  def receive_transaction(server, transaction) do
    GenServer.cast(server, {:receive_transaction, {transaction}})
  end

  ## Server Callbacks
  def init(:ok) do
    {
      :ok,
      %{
        :genesis_block => nil,
        :transactions => [],
        :blockchain => []
      }
    }
  end

  def verify_block(blockchain) do
    if(Enum.count(blockchain) == 1) do
      true
    else
      case hd(blockchain).prev_hash == List.first(tl(blockchain)).hash do
        true -> verify_block(tl(blockchain))
        false -> false
      end
    end
  end

  def handle_call({method, methodArgs}, _from, state) do
    case method do
      :get_transactions ->
        transactions = state.transactions
        {:reply, transactions, Map.update!(state, :transactions, fn _ -> [] end)}

      :get_blockchain ->
        {:reply, state.blockchain, state}

      :add_block ->
        block = methodArgs
        blockchain = state.blockchain ++ [block]

        case verify_block(Enum.reverse(blockchain)) do
          true -> {:reply, true, Map.update!(state, :blockchain, fn _ -> blockchain end)}
          false -> {:reply, false, state}
        end

      :get_genesis_block ->
        {:reply, state.genesis_block, state}
    end
  end

  def handle_cast({method, methodArgs}, state) do
    case method do
      :generate_genesis_block ->
        {pubkeyhash} = methodArgs
        # TODO: Replace with proper genesis block. hardcoding here.
        txns = [
          %{
            :hash => "dummy_hash",
            :tx_out => [
              %{
                :value => 100,
                :pk_script => "OP_HASH160 #{pubkeyhash} OP_EQUALVERIFY" #Decode base 16
              }
            ]
          }
        ]
        genesis_block = Block.create("", 0, 0, txns)
        {
          :noreply,
          Map.merge(state, %{
            :genesis_block => genesis_block,
            :blockchain => [genesis_block]
          })
        }

      :receive_transaction ->
        {transaction} = methodArgs

        new_state =
          update_in(state[:transactions], fn transactions -> transactions ++ [transaction] end)

        {:noreply, new_state}
    end
  end
end
