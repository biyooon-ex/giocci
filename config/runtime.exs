# Copy this file to your application project and set
# the values accordingly to use Giocci features.
# It is recommended to prepare `.env` and gitignore it
# to keep your servers information secret.

import Config
import Dotenvy

source!([".env", System.get_env()])

config :giocci, :giocci_zenoh,
  # The node name of your application
  my_client_node_name: env!("MY_CLIENT_NODE_NAME", :string, "client1"),
  # The nodes' name for Giocci relays
  relay_node_list:
    env!("RELAY_NODE_LIST", :string, "relay1, relay2, relay3") |> String.split(~r/[ ,]+/)
