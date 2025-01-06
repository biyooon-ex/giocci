defmodule GiocciLog do
  @moduledoc """
  log取得用

  """
  use GenServer

  @relay_name Application.get_env(:giocci_zenoh, [:system_variables, :relay_node_name], ["relay1"])

  def setup_log do
    GiocciZenoh.setup_client()
    start_link()
    GiocciZenoh.module_save(Giocci.Hello, "relay1")
  end

  def start_link do
    default_time = System.monotonic_time(:microsecond)
    default_type = "none"

    state = %{
      start_time: default_time,
      type: default_type
    }

    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  def handle_cast(:put_start_time, state) do
    new_state = %{start_time: System.monotonic_time(:microsecond), type: state.type}
    {:noreply, new_state}
  end

  def handle_call(:get_start_time, _from, state) do
    {:reply, state, state}
  end

  def module_exec_log(0) do
    :ok
  end

  def module_exec_log(n) do
    GenServer.cast(__MODULE__, :put_start_time)

    GiocciZenoh.module_exec(Giocci.Hello, :world, ["kazuma"], "relay1")
    Process.sleep(1000)
    module_exec_log(n - 1)
  end

  def finish_time do
    finish_time = System.monotonic_time(:microsecond)
    type = "zenoh?"
    %{start_time: start_time, type: type} = GenServer.call(__MODULE__, :get_start_time)

    giocci_time = finish_time - start_time
    put_log(start_time, finish_time, giocci_time, type)
  end

  def get_local_time() do
    {{year, month, day}, {time, min, sec}} = :calendar.local_time()
    local_time = "#{year}-#{month}-#{day} #{time}:#{min}:#{sec}"
  end

  def put_log(start_time, finish_time, giocci_time, type) do
    {{year, month, day}, {time, min, sec}} = :calendar.local_time()

    file_name =
      "#{year}" <> String.pad_leading("#{month}", 2, "0") <> String.pad_leading("#{day}", 2, "0")

    local_time = "#{year}-#{month}-#{day} #{time}:#{min}:#{sec}"

    log =
      local_time <>
        ", " <>
        Integer.to_string(start_time) <>
        ", " <>
        Integer.to_string(finish_time) <>
        ", " <> Integer.to_string(giocci_time) <> ", " <> type <> "\n"

    IO.inspect(log)
    File.write("data/#{file_name}_detect_log.txt", log, [:append])
  end
end
