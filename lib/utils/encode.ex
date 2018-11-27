defmodule Base58Enc do
  @character "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
  def encode(byte_series, acc \\ "")
  def encode(0, acc), do: acc

  def encode(byte_series, acc) when is_binary(byte_series) do
    byte_series
    |> :binary.decode_unsigned()
    |> encode(acc)
    |> prepend_zeros(byte_series)
  end

  def encode(byte_series, acc) do
    byte_series
    |> div(String.length(@character))
    |> encode(extended_hash(byte_series, acc))
  end

  defp extended_hash(byte_series, acc) do
    @character
    |> String.at(rem(byte_series, String.length(@character)))
    |> Kernel.<>(acc)
  end

  defp prepend_zeros(acc, byte_series) do
    byte_series
    |> encode_zeros()
    |> Kernel.<>(acc)
  end

  defp encode_zeros(byte_series) do
    byte_series
    |> leading_zeros()
    |> duplicate_zeros()
  end

  defp leading_zeros(byte_series) do
    byte_series
    |> :binary.bin_to_list()
    |> Enum.find_index(&(&1 != 0))
  end

  defp duplicate_zeros(count) do
    @character
    |> String.first()
    |> String.duplicate(count)
  end
end
