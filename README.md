[![Hex version](https://img.shields.io/hexpm/v/giocci.svg "Hex version")](https://hex.pm/packages/giocci)
[![API docs](https://img.shields.io/hexpm/v/giocci.svg?label=hexdocs "API docs")](https://hexdocs.pm/giocci)
[![License](https://img.shields.io/hexpm/l/giocci.svg)](https://github.com/b5g-ex/giocci/blob/main/LICENSE)



資源透過型計算資源プラットフォームGiocciのクライアントライブラリです



## 実行の際に必要となる他のリポジトリについて

このリポジトリgiocciは、giocci_relay(https://github.com/biyooon-ex/giocci_relay)、giocci_engine(https://github.com/biyooon-ex/giocci_engine)、と同時に使用します。
また、giocciはライブラリとして読み込んで使用します。




## 実行環境
giocci、giocci_relay、giocci_engineは以下の環境で動作します。
- Erlang 27.1.2 以降 
- Elixir 1.17.3-otp-27 以降
- Zenoh 0.11.0


## インストール方法
上記の環境を用意した上で、
以下のようにmix.exsにgiocciを追加します。


```elixir
def deps do
  [
    {:giocci, "~> 0.3.0"}
  ]
end
```
そして、mix deps.get によりgiocciを読み込んでください。

これによりgiocciのインストールは完了です。


## 準備方法

### Relayの準備
次に、Relayを配置するサーバに以下のコマンドにより、giocci_relayをクローンします。
```sh
git clone https://github.com/biyooon-ex/giocci_relay.git
```

その後、`cd giocci_relay`でディレクトリを移動した後、`mix deps.get`により必要なモジュールを読み込みます。

また、Zenohを使用するため、以下のコマンドでZenohのルータを立ち上げます
```sh
zenohd 
```

その後config/runtime.exsのmy_node_nameの値をこのRelayの名前とし、文字列の形式で設定します。
また、config/runtime.exsのengine_node_nameに使用するEngineの名前の文字列をリスト形式で入力します。
そして、config/runtime.exsのclient_node_nameに使用するClientの名前を文字列の形式で設定します。

以上でRelayの準備は完了です。


### Engineの準備

まず、Engineを配置するサーバに以下のコマンドにより、giocci_engineをクローンします。
```sh
git clone https://github.com/biyooon-ex/giocci_engine.git
```
その後、`cd giocci_engine`でディレクトリを移動した後、`mix deps.get`により必要なモジュールを読み込みます。
また、Zenohを使用するため、以下のコマンドでZenohのルータを立ち上げ、RelayのZenohルータにカスケードします。ただし、RelayのグローバルIPは各自適切なものに書き換えてください。
```sh
zenohd -e tcp/RelayのGlobalIP:7447
```
その後config/runtime.exsのmy_node_nameの値をこのEngineの名前とし、文字列の形式で設定します。
また、config/runtime.exsのrelay_node_nameに使用するRelayの名前の文字列をリスト形式で入力します。


以上でEngineの準備は完了です。



### Client(giocci)の準備

giocciをインポートした環境で、以下のコマンドでZenohルータを立ち上げ、Relayのルータにカスケードします。ただし、RelayのグローバルIPは各自適切なものに書き換えてしてください。
```sh
zenohd -e tcp/RelayのGlobalIP:7447
```
その後config/runtime.exsのmy_client_node_nameの値をこのClientの名前とし、文字列の形式で設定します。
また、config/runtime.exsのrelay_node_listに使用するRelayの名前の文字列をリスト形式で入力します。



## 実行方法例　〜giocci_exampleを基に〜

以上の準備を終えた状態でGiocciの実行例を述べます。

実行例での注意として、Relayの名前はRelay1、Engineの名前はEngine1を使用しています。

まず、Relayを配置したサーバでターミナルから`iex -S mix`でgiocci_relayを起動します。その後`GiocciRelayZenoh.setup_relay()`でセットアップを行います。
同様に、Engineを配置したサーバでターミナルから`iex -S mix`でgiocci_engineを起動します。その後`GiocciEngineZenoh.setup_engine()`でセットアップを行います。



以上でRelayとEngineのスタンバイは完了です。

Erlang、Elixir、Zenohをインストールした環境にgiocci_exampleのリポジトリををクローンします。

```sh
git clone https://github.com/biyooon-ex/giocci_example.git
```

クローンした後`cd giocci_example`によりディレクトリを移動し、mix.exsのdepsにgiocciを追加します。
```elixir
def deps do
  [
    {:giocci, "~> 0.3.0"}
  ]
end
```

その後`mix dpes.get`によりgiocciをインストールした後、`iex -S mix`によりElixirを起動します。
そして`GiocciZenoh.setup_client()`でセットアップを完了します。 

以上でモジュールを送信し、実行する準備は完了です。

### 1.モジュールの送信
モジュールの送信では以下の関数を用います。この関数の第一引数は、送信するモジュール名で、第二引数はこのリクエスト送信するRelayの名前の文字列です。
```sh
GiocciZenoh.module_save(Module_name,"relay_name")
```

今回はGiocciExampleのモジュールを先程用意した"Relay1"に送信するため、`GiocciZenoh.module_save(GiocciExample,"relay1")`をElixir上で実行します。

Engine上のターミナルで`[info] v module: GiocciExample is loaded.`が出れば成功です。

### 2.モジュールの実行
モジュールの実行では以下の関数を用います。この関数の第一引数は、送信するモジュール名で、第二引数は実行する関数名のアトム、第三引数は実行する関数に渡す引数のリスト、第四引数はこのリクエストを送信するRelayの名前の文字列です。

```sh
GiocciZenoh.module_exec(Module_name,:function,["arity"],"relay_name")
```

今回は先程保存したGiocciExampleのモジュールの、world関数に"kazuma"の引数を与え、"relay1"にリクエストを行うので、`GiocciZenoh.module_exec(GiocciExample,:world,["kazuma"],"relay1")`を実行します。

giocci_exampleに実行時間と引数の文字を含む`[[XXXX, "Hello kazuma!!"], " from engine"]`が表示されれば成功です。



Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/giocci>.

