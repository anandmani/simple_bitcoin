defmodule SimpleBitcoin do
  def start(numParticipants) do
    username = Enum.map(1..numParticipants, fn x -> IO.gets("User #{x}: ") |> String.trim end)
    Enum.map(username, fn username -> Wallet.start_link(username) end)

    Bitcoind.start_link()

    Enum.map(1..1, fn x -> Miner.start_link("miner" <> Integer.to_string(x)) end)
  end
end
