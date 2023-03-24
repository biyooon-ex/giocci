defmodule GiocciLib.CLI.RegContact do
  require Logger

  # *** below is an example ***
  @relay {:global, :relay}

  defmodule Element do
    defstruct attr_device: "ex. led, button",
              attr_type: "ex. din, dout",
              contact_name: :contact_name,
              contact_value: nil,
              node_name: {:global, :my_node_name}
  end

  def start_register(
        attr_device: attr_device,
        attr_type: attr_type,
        contact_name: contact_name,
        contact_value: contact_value,
        node_name: node_name
      ) do
    vcontact_element = %Element{
      attr_device: attr_device,
      attr_type: attr_type,
      contact_name: contact_name,
      contact_value: contact_value,
      node_name: node_name
    }

    Logger.info(inspect(Map.from_struct(vcontact_element)))
    GenServer.cast(@relay, {:reg_contact, Map.from_struct(vcontact_element)})

    :ok
  end
end
