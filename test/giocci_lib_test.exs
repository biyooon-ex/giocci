defmodule GiocciLibTest do
  use ExUnit.Case
  doctest GiocciLib

  test "greets the world" do
    assert GiocciLib.hello() == :world
  end
end
