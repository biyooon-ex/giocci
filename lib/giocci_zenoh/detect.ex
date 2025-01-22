defmodule GiocciZenoh.Detect do
  alias Zenohex.Config
  alias Zenohex.Config.Connect
  alias Zenohex.Config.Scouting
  alias Zenohex.Session
  alias Zenohex.Publisher

  def detect(publisher, value, subscriber, receive_timeout) do
    Publisher.put(publisher, value)

    case Zenohex.Subscriber.recv_timeout(subscriber, receive_timeout * 1_000) do
      {:ok, sample} -> {:ok, :erlang.binary_to_term(sample.value)}
      {:error, :timeout} -> {:error, "Zenoh Timeout"}
      {:error, reason} -> {:error, Exception.message(reason)}
    end
  end

  def create_zenoh_session() do
    relays = Application.fetch_env!(:biyooon_detect_frontend_phx, :relays)
    engines = Application.fetch_env!(:biyooon_detect_frontend_phx, :engines)

    # Set endpoint config
    config =
      %Config{
        connect: %Connect{endpoints: get_zrouter(relays)},
        scouting: %Scouting{delay: 200}
      }

    # Open session, and declare publishers and subscriber
    {:ok, session} = Zenohex.open(config)
    {:ok, publishers} = declare_publishers(session, relays)
    {:ok, subscribers} = declare_subscribers(session, engines)

    %{:pubs => publishers, :subs => subscribers}
  end

  defp get_zrouter(relays) do
    relays
    |> Map.values()
    |> Enum.map(fn ip -> "tcp/#{ip}:7447" end)
  end

  defp declare_publishers(session, relays) do
    relays_keys = relays |> Map.keys()
    pub_key_prefix = Application.fetch_env!(:giocci, :pub_key_prefix)

    publishers_list =
      relays_keys
      |> Enum.map(fn key_atom ->
        key = Atom.to_string(key_atom)
        {:ok, publisher} = Session.declare_publisher(session, pub_key_prefix <> key)
        publisher
      end)

    publishers = Enum.zip(relays_keys, publishers_list) |> Enum.into(%{})

    {:ok, publishers}
  end

  defp declare_subscribers(session, engines) do
    sub_key_prefix = Application.fetch_env!(:giocci, :sub_key_prefix)

    subscriber_list =
      engines
      |> Enum.map(fn key_atom ->
        key = Atom.to_string(key_atom)

        {:ok, subscriber} =
          Session.declare_subscriber(session, sub_key_prefix <> key <> "/detected_data")

        subscriber
      end)

    subscribers = Enum.zip(engines, subscriber_list) |> Enum.into(%{})

    {:ok, subscribers}
  end
end
