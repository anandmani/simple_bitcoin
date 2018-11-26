defmodule Bitcoind do
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  @doc """
    Generates a genesis block that pays pubkeyhash 50 bitcoins
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
      :ok, %{
        :genesis_block => nil,
        :transactions => []
      }
    }
  end

  def handle_call({method, _methodArgs}, _, state) do
    case method do
      :get_genesis_block ->
        {:reply, state.genesis_block, state}
    end
  end

  def handle_cast({method, methodArgs}, state) do
    case method do
      :generate_genesis_block ->
        {pubkeyhash} = methodArgs
        #TODO: Replace with proper genesis block. hardcoding here.
        genesis_block = %{
          :txns => [
            %{
              :hash => "abcd",
              :tx_out => [
                %{
                  :value => 50 * 100_000_000,
                  :pk_script => "OP_HASH160 #{pubkeyhash} OP_EQUALVERIFY"
                }
              ]
            }
          ]
        }
        {:noreply, Map.merge(state, %{:genesis_block => genesis_block})}
      :receive_transaction ->
        {transaction} = methodArgs
        new_state = update_in(state[:transactions], fn transactions -> transactions ++ [transaction] end)
        {:noreply, new_state}
    end

  end

end
