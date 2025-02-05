[![Hex version](https://img.shields.io/hexpm/v/giocci.svg "Hex version")](https://hex.pm/packages/giocci)
[![API docs](https://img.shields.io/hexpm/v/giocci.svg?label=hexdocs "API docs")](https://hexdocs.pm/giocci)
[![License](https://img.shields.io/hexpm/l/giocci.svg)](https://github.com/b5g-ex/giocci/blob/main/LICENSE)

# Giocci

Client Library for Giocci

## Description

Giocci is a computational resource permeating wide-area distributed platform towards the B5G era.

This repository is a library that provides functionality for the client in Giocci environment.
It should be used with [giocci_relay](https://github.com/b5g-ex/giocci_relay) [giocci_engine](https://github.com/b5g-ex/giocci_engine) installed onto Giocci server(s).

The detailed instructions will be appeared ASAP,,,

## Environment
- Erlang after 27.1.2 
- Elixir after 1.17.3-otp-27
- Zenoh 0.11.0

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `giocci` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:giocci, "~> 0.2.0"}
  ]
end
```
then, uperform mix deps.get and iex -S mix
On Elixir runtime,do 
```sh
GiocciZenoh.setup_client()
``` 

After all Giocci setup including giocci_relay and giocci_engine,you can setup Zenoh router
```sh
Zenohd -e tcp/GlobalIP at Relay:7447
```


In the end,you can use giocci

## Usage

you can use 2 function, GiocciZenoh.module_save\2 and GioddiZenoh.mocule_exec\4.

module_save function is used as below.
```sh
GiocciZenoh.module_save(Module_name,"relay_name")
```
In this case, input module is loaded at giocci_engine.


On the other hand, module_exec function is used as below.
```sh
GiocciZenoh.module_exec(Module_name,:function,["arity"],"relay_name")
```
In this case, module that is loaded at engine is performed at engine, and Giocci receives its result.

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/giocci>.

