IRC client library, supporting Lwt and Unix blocking IO.

[![Build status](https://travis-ci.org/johnelse/ocaml-irc-client.png?branch=master)](https://travis-ci.org/johnelse/ocaml-irc-client)
[![Coverage Status](https://coveralls.io/repos/johnelse/ocaml-irc-client/badge.svg?branch=master)](https://coveralls.io/r/johnelse/ocaml-irc-client?branch=master)
[![API reference](https://img.shields.io/badge/docs-API_reference-blue.svg)](https://johnelse.github.io/ocaml-irc-client)

Build dependencies
------------------

* [lwt](http://ocsigen.org/lwt/) (optional)
* [oasis](https://github.com/ocaml/oasis)
* [oUnit](http://ounit.forge.ocamlcore.org/)

The latest tagged version is available via [opam](http://opam.ocamlpro.com): `opam install irc-client`

Usage
-----

Simple bot which connects to a channel, sends a message, and then logs all
messages in that channel to stdout:

```ocaml
open Lwt
module C = Irc_client_lwt

let host = "localhost"
let port = 6667
let realname = "Demo IRC bot"
let nick = "demoirc"
let username = nick
let channel = "#demo_irc"
let message = "Hello, world!  This is a test from ocaml-irc-client"

let callback _connection result =
  let open Irc_message in
  match result with
  | Result.Ok msg ->
    Lwt_io.printf "Got message: %s\n" (to_string msg)
  | Result.Error e ->
    Lwt_io.printl e

let lwt_main =
  Lwt_unix.gethostbyname host
  >>= fun he -> C.connect ~addr:(he.Lwt_unix.h_addr_list.(0))
                  ~port ~username ~mode:0 ~realname ~nick ()
  >>= fun connection -> Lwt_io.printl "Connected"
  >>= fun () -> C.send_join ~connection ~channel
  >>= fun () -> C.send_privmsg ~connection ~target:channel ~message
  >>= fun () -> C.listen ~connection ~callback ()
  >>= fun () -> C.send_quit ~connection

let _ = Lwt_main.run lwt_main
```

Compile the above with:

```
ocamlfind ocamlopt -package irc-client.lwt -linkpkg code.ml
```

Alternatively, you can find it at `examples/example1.ml`; enable its compilation
with `./configure --enable-examples --enable-lwt`.
