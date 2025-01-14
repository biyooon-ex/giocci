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
  def handle_call({:module_save, encode_module}, _from, state) do
    module_save_reply = GenServer.call(state.relay, {:module_save, encode_module})

    {:reply, module_save_reply, state}
  end

  @impl true
  def handle_call({:rpc, module, function, arity}, _from, state) do
    rpc_reply = GenServer.call(state.relay, {:rpc, module, function, arity})

    {:reply, rpc_reply, state}
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
    encode_module = Giocci.CLI.ModuleConverter.encode(module)

    GenServer.call(__MODULE__, {:module_save, encode_module})
  end

  def put() do
  end

  def put_detect_log(total_timie, processing_time, model, backend) do
    GenServer.cast(__MODULE__, {:put_detect_log, total_timie, processing_time, model, backend})
  end

  def rpc(module, function, arity) do
    GenServer.call(__MODULE__, {:rpc, module, function, arity})
  end
end
