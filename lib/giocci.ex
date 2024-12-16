defmodule Giocci do
  @moduledoc """
  `Giocci.start_link([DESTINATION_GIOCCI_RELAY])` で起動する。

  ## Examples

      iex> Giocci.start_link([{:global, :relay}])

  """

  use GenServer
  require Logger

  @timeout_ms 180_000

  #
  # Client API
  #
  def start_link([state]) do
    state = %{relay: state}
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  def stop(pname) do
    GenServer.stop(pname)
  end

  #
  #  Callbacks
  #
  @impl true
  def handle_call({:detect, binary, destination}, _from, state) do
    detection = GenServer.call(state.relay, {:detect, binary, destination}, @timeout_ms)

    {:reply, detection, state}
  end

  @impl true
  def handle_call({:get, vcontact_id}, _from, state) do
    vcontact = GenServer.call(state.relay, {:get, vcontact_id})

    {:reply, vcontact, state}
  end

  @impl true
  def handle_call(:list, _from, state) do
    current_list = GenServer.call(state.relay, :list)

    {:reply, current_list, state}
  end

  @impl true
  def handle_call({:list_filter, filter_key, filter_value}, _from, state) do
    filtered_list = GenServer.call(state.relay, {:list_filter, filter_key, filter_value})

    {:reply, filtered_list, state}
  end

  @impl true
  def handle_cast({:delete, vcontact_id}, state) do
    GenServer.cast(state.relay, {:delete, vcontact_id})

    {:noreply, state}
  end

  def handle_cast({:put_detect_log, total_timie, processing_time, model, backend}, state) do
    GenServer.cast(state.relay, {:put_detect_log, total_timie, processing_time, model, backend})

    {:noreply, state}
  end

  @impl true
  def init(state) do
    {:ok, state}
  end

  @impl true
  def terminate(reason, _state) do
    reason
  end

  #
  # Function
  #
  def delete(vcontact_id) do
    GenServer.call(__MODULE__, {:delete, vcontact_id})
  end

  def detect(binary, destination) do
    GenServer.call(__MODULE__, {:detect, binary, destination}, @timeout_ms)
  end

  def get(vcontact_id) do
    GenServer.call(__MODULE__, {:get, vcontact_id})
  end

  def list() do
    GenServer.call(__MODULE__, :list)
  end

  def list_filter(filter_key, filter_value) do
    GenServer.call(__MODULE__, {:list_filter, filter_key, filter_value})
  end

  def module_save(module) do
    encode_module = [Giocci.CLI.ModuleConverter.encode(module), :module_save]
    ## zenohを起動してpub
    {:ok, session} = Zenohex.open()
    {:ok, publisher} = Zenohex.Session.declare_publisher(session, "from/client/to/relay")
    Zenohex.Publisher.put(publisher, encode_module |> :erlang.term_to_binary() |> Base.encode64())
  end

  def put() do
  end

  def put_detect_log(total_timie, processing_time, model, backend) do
    GenServer.cast(__MODULE__, {:put_detect_log, total_timie, processing_time, model, backend})
  end

  def module_exec(module, function, arity) do
    ## zenohを起動してpub
    {:ok, session} = Zenohex.open()
    {:ok, publisher} = Zenohex.Session.declare_publisher(session, "from/client/to/relay")

    Zenohex.Publisher.put(
      publisher,
      [module, function, arity, :module_exec] |> :erlang.term_to_binary() |> Base.encode64()
    )
  end

  def callback(state, m) do
    ## 　Engineから(Relayを通して)送られたメッセージを抽出し、表示
    %{
      key_expr: erkey,
      value: msgint,
      kind: kind,
      reference: reference
    } = m

    msg = msgint |> Base.decode64!() |> :erlang.binary_to_term()

    IO.inspect(msg)
  end

  def start_link() do
    ## RelayからClientに返送するsubをセットアップする
    ## ClientのZenohセッションを起動
    {:ok, session} = Zenohex.open()
    ## subのキーをたてる
    {:ok, subscriber} = Zenohex.Session.declare_subscriber(session, "from/relay/to/client")

    ## 状態として次の状態をもつ
    state = %{subscriber: subscriber, callback: &callback/2, id: RCsession}

    ## 上記の状態を保存する用のGenServerの起動
    GenServer.start_link(__MODULE__, state, name: RCsession)
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
