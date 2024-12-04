defmodule Giocci.CLI.ModuleConverter do
  @doc """
  moduleをBase64エンコードする。

  ## Example
      iex> Giocci.CLI.ModuleConverter.encode(MODULE_NAME)
  """
  def encode(module) do
    module
    |> :code.get_object_code()
    |> :erlang.term_to_binary()
    |> Base.encode64()
  end

  @doc """
  Base64エンコードされたmoduleをデコードする。

  ## Exmaple
      iex> Giocci.CLI.ModuleConverter.decode(encode_module)
  """
  def decode(encode_module) do
    {name, binary, path} =
      encode_module
      |> Base.decode64!()
      |> :erlang.binary_to_term()

    {name, binary, path}
  end

  @doc """
  デコードされたmoduleを読み込む。

  ## Example
      iex> Giocci.CLI.ModuleConverter.load({name, binary, path})
      or
      iex> Giocci.CLI.ModuleConverter.decode(encode_module) |> Giocci.CLI.ModuleConverter.load()
  """
  def load({name, binary, path}) do
    :code.load_binary(name, path, binary)
  end







end
