defmodule Giocci.Hello do

  def add({a, b}) do
    a + b
  end

  def sub({a, b}) do
    a - b
  end

  def world(name) do
    IO.inspect("Hello #{name}!!")
  end

  def world() do
    :world
  end
end
