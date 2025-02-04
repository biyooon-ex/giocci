defmodule GiocciZenoh do
  @moduledoc """
  `GiocciZenoh.setup_client()` で起動する。

  ## Examples

      iex> GiocciZenoh.setup_client()

  """

  use GenServer
  require Logger

  def module_save(module, relay_name_tosend) do
    ## モジュールをエンコードする
    encode_module = [Giocci.CLI.ModuleConverter.encode(module), :module_save]
    id = (my_client_node_name() <> relay_name_tosend) |> String.to_atom()
    ## publisherをセッションから作成しpublishする
    [publisher, my_client_name, relay_name] =
      GenServer.call(id, :call_publisher)

    Zenohex.Publisher.put(publisher, encode_module |> :erlang.term_to_binary() |> Base.encode64())
  end

  def module_exec(module, function, arity, relay_name_tosend) do
    ## publisherをセッションから作成しpublishする
    id = (my_client_node_name() <> relay_name_tosend) |> String.to_atom()

    [publisher, my_client_name, relay_name] =
      GenServer.call(id, :call_publisher)

    Zenohex.Publisher.put(
      publisher,
      [module, function, arity, :module_exec] |> :erlang.term_to_binary() |> Base.encode64()
    )
  end

  def setup_client() do
    ## sub用のセッションとキーを設定

    {:ok, session} = Zenohex.open()
    ## subのキーをたてる
    {:ok, subscriber} =
      Zenohex.Session.declare_subscriber(
        session,
        "key_prefix/giocci/relay_to_client/" <> my_client_node_name()
      )

    id = (my_client_node_name() <> "sub") |> String.to_atom()

    state = %{
      subscriber: subscriber,
      callback: &callback/2,
      id: id,
      session: session,
      my_client_name: my_client_node_name()
    }

    ## 上記の状態を保存する用のGenServerの起動
    Logger.info(inspect(id))
    GenServer.start_link(__MODULE__, state, name: id)
    ## subの開始
    subscriber_loop(state)
    {:ok, state}
    create_session(relay_node_list())
  end

  @doc """
    Engineから(Relayを通して)送られたメッセージを抽出し、表示
  """
  def callback(_state, message) do
    %{
      key_expr: erkey,
      value: message_intermediate
    } = message

    message_readable = message_intermediate |> Base.decode64!() |> :erlang.binary_to_term()
    Logger.info("#{inspect(message_readable)}")
  end

  @doc """
    RelayからClientに返送するpubsubをセットアップする
  """
  def start_link(relay_name) do
    ## ClientのZenohセッションを起動
    {:ok, session} = Zenohex.open()

    # ## subのキーをたてる
    # {:ok, subscriber} =
    #   Zenohex.Session.declare_subscriber(
    #     session,
    #     "key_prefix/giocci/relay_to_client/" <> my_client_node_name()
    # )

    {:ok, publisher} =
      Zenohex.Session.declare_publisher(
        session,
        "key_prefix/giocci/client_to_relay/" <> relay_name
      )

    id = (my_client_node_name() <> relay_name) |> String.to_atom()
    ## 状態として次の状態をもつ
    state = %{
      publisher: publisher,
      id: id,
      session: session,
      my_client_name: my_client_node_name(),
      relay_name: relay_name
    }

    ## 上記の状態を保存する用のGenServerの起動
    Logger.info(inspect(id))
    GenServer.start_link(__MODULE__, state, name: id)
    {:ok, state}
  end

  def stop(pname) do
    GenServer.stop(pname)
  end

  @impl true
  def init(state) do
    {:ok, state}
  end

  @impl true
  def terminate(reason, _state) do
    reason
  end

  @impl true
  def handle_call(:call_publisher, _from, state) do
    reply = [state.publisher, state.my_client_name, state.relay_name]
    {:reply, reply, state}
  end

  @impl true
  def handle_info(:loop, state) do
    subscriber_loop(state)
    {:noreply, state}
  end

  defp create_session([]) do
    :ok
  end

  ## セッションを作る関数
  defp create_session(relay_list) do
    [relay_name | tail] = relay_list

    start_link(relay_name)
    create_session(tail)
  end

  ## subを永続化する関数
  defp subscriber_loop(state) do
    case Zenohex.Subscriber.recv_timeout(state.subscriber, 10_000) do
      {:ok, sample} ->
        state.callback.(state, sample)
        send(state.id, :loop)

      {:error, :timeout} ->
        send(state.id, :loop)

      {:error, error} ->
        Logger.error("unexpected error #{inspect(error)}")
    end
  end

  defp my_client_node_name(),
    do: Application.fetch_env!(:giocci, :giocci_zenoh)[:my_client_node_name]

  defp relay_node_list(),
    do: Application.fetch_env!(:giocci, :giocci_zenoh)[:relay_node_list]
end
