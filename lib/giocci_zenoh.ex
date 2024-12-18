defmodule GiocciZenoh do
  @moduledoc """
  `Giocci.start_link([DESTINATION_GIOCCI_RELAY])` で起動する。

  ## Examples

      iex> Giocci.start_link([{:global, :relay}])

  """

  use GenServer
  require Logger

  def module_save(module) do
    client_name = "client1"
    relay_name = "relay2"
    encode_module = [Giocci.CLI.ModuleConverter.encode(module), :module_save]
    ## zenohを起動してpub

    {:ok, session} = Zenohex.open()
    IO.inspect("from/" <> client_name <> "/to/" <> relay_name)

    {:ok, publisher} =
      Zenohex.Session.declare_publisher(session, "from/" <> client_name <> "/to/" <> relay_name)

    Zenohex.Publisher.put(publisher, encode_module |> :erlang.term_to_binary() |> Base.encode64())
  end

  def module_exec(module, function, arity) do
    ## zenohを起動してpub
    client_name = "client1"
    relay_name = "relay2"
    {:ok, session} = Zenohex.open()

    {:ok, publisher} =
      Zenohex.Session.declare_publisher(session, "from/" <> client_name <> "/to/" <> relay_name)

    IO.inspect("from/" <> client_name <> "/to/" <> relay_name)

    Zenohex.Publisher.put(
      publisher,
      [module, function, arity, :module_exec] |> :erlang.term_to_binary() |> Base.encode64()
    )
  end

  def callback(state, message) do
    ## 　Engineから(Relayを通して)送られたメッセージを抽出し、表示
    %{
      key_expr: erkey,
      value: message_intermediate,
      kind: kind,
      reference: reference
    } = message

    readable_msg = message_intermediate |> Base.decode64!() |> :erlang.binary_to_term()

    IO.inspect(readable_msg)
  end

  def start_link() do
    ## RelayからClientに返送するsubをセットアップする
    ## ClientのZenohセッションを起動
    client_name = "client1"
    relay_name = "relay2"
    {:ok, session} = Zenohex.open()
    ## subのキーをたてる
    {:ok, subscriber} =
      Zenohex.Session.declare_subscriber(session, "from/" <> relay_name <> "/to/" <> client_name)

    ## 状態として次の状態をもつ
    state = %{subscriber: subscriber, callback: &callback/2, id: Relay2Clientsession}

    ## 上記の状態を保存する用のGenServerの起動
    GenServer.start_link(__MODULE__, state, name: Relay2Clientsession)
    ## subの開始
    recv_timeout(state)
    {:ok, state}
  end

  def handle_info(:loop, state) do
    recv_timeout(state)
    {:noreply, state}
  end

  defp recv_timeout(state) do
    ## subを永続化する関数
    case Zenohex.Subscriber.recv_timeout(state.subscriber, 10_000) do
      {:ok, sample} ->
        state.callback.(state, sample)
        send(state.id, :loop)

      {:error, :timeout} ->
        send(state.id, :loop)

      {:error, error} ->
        Logger.error(inspect(error))
    end
  end
end
