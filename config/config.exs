import Config

config :giocci_zenoh, :system_variables,
  my_node_name: "client1",
  relay_node_name: ["relay1", "relay2", "relay3"]

# import_config "#{config_env()}.exs"
