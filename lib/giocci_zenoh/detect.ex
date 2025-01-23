defmodule GiocciZenoh.Detect do
  alias Zenohex.Config
  alias Zenohex.Config.Connect
  alias Zenohex.Config.Scouting
  alias Zenohex.Session
  alias Zenohex.Publisher
  alias Zenohex.Subscriber

  def detect(session, relay, engine, magic_number, payload, receive_timeout) do
    pub_key_prefix = Application.fetch_env!(:giocci, :pub_key_prefix)
    relay_name = Atom.to_string(relay)
    pub_key = pub_key_prefix <> relay_name <> "/" <> Integer.to_string(magic_number)
    {:ok, publisher} = Session.declare_publisher(session, pub_key)

    sub_key_prefix = Application.fetch_env!(:giocci, :sub_key_prefix)
    engine_name = Atom.to_string(engine)

    sub_key =
      sub_key_prefix <> engine_name <> "/detected_data/" <> Integer.to_string(magic_number)

    {:ok, subscriber} = Session.declare_subscriber(session, sub_key)

    Publisher.put(publisher, payload)

    case Subscriber.recv_timeout(subscriber, receive_timeout * 1_000) do
      {:ok, sample} -> {:ok, :erlang.binary_to_term(sample.value)}
      {:error, :timeout} -> {:error, "Zenoh Timeout"}
      {:error, reason} -> {:error, Exception.message(reason)}
    end
  end

  def create_zenoh_session() do
    relays = Application.fetch_env!(:biyooon_detect_frontend_phx, :relays)

    # Set endpoint config
    config =
      %Config{
        connect: %Connect{endpoints: get_zrouter(relays)},
        scouting: %Scouting{delay: 200}
      }

    # Open session
    {:ok, session} = Zenohex.open(config)
    %{:session => session}
  end

  defp get_zrouter(relays) do
    relays
    |> Map.values()
    |> Enum.map(fn ip -> "tcp/#{ip}:7447" end)
  end
end
