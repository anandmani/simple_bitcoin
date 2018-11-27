defmodule Signature do
  def generate(private_key, message),
    do: :crypto.sign(:ecdsa, :sha256, message, [private_key, :secp256k1])

  def verify(public_key, signature, message),
    do: :crypto.verify(:ecdsa, :sha256, message, signature, [public_key, :secp256k1])
end
