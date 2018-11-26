defmodule DnsSeed do
  @moduledoc """
    DNS Seed maintains a list of all participant pids and bitcoind pid in the network. (Doesn't include miners?)
  """
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  @doc """
    Returns list of all pids in the network
  """
  def get_all_participants(server) do
    GenServer.call(server, {:get_all_participants, {}})
  end

  @doc """
    Adds pid of participant who wants to join the network
  """
  def register_participant(server, pid) do
    GenServer.cast(server, {:register_participant, {pid}})
  end

  ## Server Callbacks
  def init(:ok) do
    {:ok, []}
  end

  def handle_call({method, _methodArgs}, _, state) do
    case method do
      :get_all_participants ->
        {:reply, state, state}
    end
  end

  def handle_cast({method, methodArgs}, state) do
    case method do
      :register_participant ->
        {pid} = methodArgs
        {:noreply, state ++ [pid]}
    end
  end
end
