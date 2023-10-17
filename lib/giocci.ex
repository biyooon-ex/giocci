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

  def put() do
  end
end
