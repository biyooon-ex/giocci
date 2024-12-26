defmodule GiocciZenoh do
  @moduledoc """
  `GiocciZenoh.start_link()` で起動する。

  ## Examples

      iex> GiocciZenoh.start_link()

  """

  use GenServer
  require Logger

  @client_name Application.get_env(:giocci_zenoh, :system_variables)[:my_node_name]
  @relay_name Application.get_env(:giocci_zenoh, :system_variables)[:relay_node_name]

  def module_save(module, relay_name_tosend) do
    ## モジュールをエンコードする
    encode_module = [Giocci.CLI.ModuleConverter.encode(module), :module_save]
    id_string = @client_name <> relay_name_tosend
    ## publisherをセッションから作成しpublishする
    [publisher, client_name, relay_name] =
      GenServer.call(String.to_atom(id_string), :call_publisher)

    Logger.info("from/" <> client_name <> "/to/" <> relay_name)
    Zenohex.Publisher.put(publisher, encode_module |> :erlang.term_to_binary() |> Base.encode64())
  end

  def module_exec(module, function, arity, relay_name_tosend) do
    ## publisherをセッションから作成しpublishする
    id_string = @client_name <> relay_name_tosend

    [publisher, client_name, relay_name] =
      GenServer.call(String.to_atom(id_string), :call_publisher)

    Logger.info("from/" <> client_name <> "/to/" <> relay_name)

    Zenohex.Publisher.put(
      publisher,
      [module, function, arity, :module_exec] |> :erlang.term_to_binary() |> Base.encode64()
    )
  end

  def setup_client() do
    create_session(@relay_name)
  end

  def callback(state, message) do
    ## 　Engineから(Relayを通して)送られたメッセージを抽出し、表示
    %{
      key_expr: erkey,
      value: message_intermediate,
      kind: kind,
      reference: reference
    } = message

    relay_list = @relay_name
    message_readable = message_intermediate |> Base.decode64!() |> :erlang.binary_to_term()

    Enum.each(relay_list, fn relay_name ->
      case "from/" <> relay_name <> "/to/" <> @client_name do
        erkey -> Logger.info(message_readable, erkey)
        _ -> IO.puts("No match")
      end
    end)

    # case erkey do
    #   "from/" <> relay_list <> "/to/" <> @client_name = erkey ->

    #   _ = erkey ->
    #     Logger.error(inspect("no match"))
    # end
  end

  def start_link(relay_name) do
    ## RelayからClientに返送するsubをセットアップする
    ## ClientのZenohセッションを起動
    client_name = @client_name
    {:ok, session} = Zenohex.open()
    ## subのキーをたてる
    {:ok, subscriber} =
      Zenohex.Session.declare_subscriber(session, "from/" <> relay_name <> "/to/" <> client_name)

    {:ok, publisher} =
      Zenohex.Session.declare_publisher(session, "from/" <> client_name <> "/to/" <> relay_name)

    id_string = client_name <> relay_name
    ## 状態として次の状態をもつ
    state = %{
      subscriber: subscriber,
      publisher: publisher,
      callback: &callback/2,
      id: String.to_atom(id_string),
      session: session,
      client_name: client_name,
      relay_name: relay_name
    }

    ## 上記の状態を保存する用のGenServerの起動
    Logger.info(id_string)
    GenServer.start_link(__MODULE__, state, name: String.to_atom(id_string))
    ## subの開始
    subscriber_loop(state)
    {:ok, state}
  end

  def handle_call(:call_publisher, from, state) do
    reply = [state.publisher, state.client_name, state.relay_name]
    {:reply, reply, state}
  end

  def handle_info(:loop, state) do
    subscriber_loop(state)
    {:noreply, state}
  end

  defp create_session([]) do
    :ok
  end

  @doc """
    セッションを作る関数

  """

  defp create_session(relay_list) do
    [relay_name | tail] = relay_list

    start_link(relay_name)
    create_session(tail)
  end

  defp subscriber_loop(state) do
    ## subを永続化する関数
    case Zenohex.Subscriber.recv_timeout(state.subscriber, 10_000) do
      {:ok, sample} ->
        state.callback.(state, sample)
        send(state.id, :loop)

      {:error, :timeout} ->
        send(state.id, :loop)

      {:error, error} ->
        Logger.error(inspect(error))

      {_, _} ->
        Logger.error("unexpected error")
    end
  end
end
