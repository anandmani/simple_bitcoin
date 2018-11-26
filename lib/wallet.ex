defmodule Wallet do
  use GenServer

  def start_link(username) do
    name = String.to_atom(username)
    {:ok, pid} = GenServer.start_link(__MODULE__, :ok, [])
    Process.register(pid, name)
    create_key_pair(name)
    create_signature(name)
    calculate_address(name)
    if(username != "bob") do
      make_transaction(name)
    end
    Process.whereis(name)
  end

  def create_key_pair(server) do
    GenServer.cast(server, {:create_key_pair})
  end

  def create_signature(server) do
    GenServer.cast(server, {:create_signature})
  end

  def calculate_address(server) do
    GenServer.cast(server, {:calculate_address})
  end

  def make_transaction(server) do
    GenServer.cast(server, {:make_transaction})
  end

  def get_address(server, signature, public_key, message) do
    GenServer.call(server, {:get_address, {signature, public_key, message}})
  end

  def init(:ok) do
    {:ok,
      %{
        :private_key => nil,
        :public_key => nil,
        :signature => nil,
        :address => nil,
        :balance => 0
      }
    }
  end
  
  def generate_key_pair, do: :crypto.generate_key(:ecdh, :secp256k1) 

  def write(private_key, public_key) do
    with file_path = ".keys/key",
      :ok <- File.mkdir_p(".keys"),
      :ok <- File.write(file_path, private_key),
      :ok <- File.write("#{file_path}.pub", public_key) do
        file_path
    else
      {:error, error} -> :file.format_error(error)
    end
  end

  def read() do
    with file_path = ".keys/key",
      {:ok, private_key} <- File.read(file_path),
      {:ok, public_key} <- File.read("#{file_path}.pub") do
        {private_key, public_key}
    else
      {:error, error} -> :file.format_error(error)
    end
  end

  def calc_address(private_key, version_bytes) do
    private_key
    |> get_public_key()
    |> hash(:sha256)
    |> hash(:ripemd160)
    |> prepend_version(version_bytes)
    |> encode()
  end

  def get_public_key(private_key) do
    private_key
    |> String.valid?()
    |> decode_key(private_key)
    |> generate_public_key()
  end
  
  defp decode_key(isValid, private_key) do
    case isValid do
      true -> Base.decode16!(private_key)
      false -> private_key
    end
  end

  defp generate_public_key(private_key) do
    with {public_key, private_key} <-
      :crypto.generate_key(:ecdh, :secp256k1, private_key),
    do: public_key
  end

  defp hash(key, hashing_algo), do:
    :crypto.hash(hashing_algo, key)

  def prepend_version(public_hash, version_bytes) do
    version_bytes
    |> Kernel.<>(public_hash)
  end

  def encode(version_hash) do
    version_hash
    |> hash(:sha256)
    |> hash(:sha256)
    |> checksum()
    |> append(version_hash)
    |> Base58Enc.encode()
  end

  defp checksum(<<checksum::bytes-size(4), _::bits>>), do: checksum

  defp append(checksum, hash), do: hash<>checksum

  def handle_cast({method}, state) do
    case method do
      :create_key_pair ->
        {public_key, private_key} = generate_key_pair()
        write(private_key, public_key)
        read()
        {:noreply, Map.merge(state, %{:private_key => private_key, :public_key => public_key})}
      
      :create_signature ->
        signature = Signature.generate(state.private_key, "")
        {:noreply, Map.merge(state, %{:signature => signature})}

      :calculate_address ->
        address = calc_address(state.private_key, <<0x00>>)
        {:noreply, Map.merge(state, %{:address => address})}

      :make_transaction ->
        server = String.to_atom("bob")
        if (Process.whereis(server) != nil) do
          receiver_address = get_address(server, state.signature, state.public_key, "")
          add_transaction()
        end
        {:noreply, state}
    end
  end

  def handle_call({method, methodArgs}, _from, state) do
    case method do
      :get_address ->
        {signature, public_key, message} = methodArgs
        bool = Signature.verify(public_key, signature, message)
        case bool do
          true -> {:reply, state.address, state}
          false -> {:reply, nil, []} 
        end
    end
  end

  def add_transaction do
    Process.send_after(self(), :add_transaction, 7*1000)
  end

  def handle_info(:add_transaction, state) do
    Bitcoind.new_transaction(:bitcoind, "5F4DF959A11580FC14AA6B139ADB2AB40A2CFDE5399C1CB6F7C9968EAE5A825F")
    add_transaction()
    {:noreply, state}
  end
end
