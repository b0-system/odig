# ocaml-dispatch

ocaml-dispatch provides a basic mechanism for dispatching a request to a
handler based on hierarchical path names conventionally found in URIs. It can be
used both for dispatching requests in a server, as well as handing changes to
hierarchical fragments in a client-side application.

[![Build Status](https://travis-ci.org/inhabitedtype/ocaml-dispatch.svg?branch=master)](https://travis-ci.org/inhabitedtype/ocaml-dispatch)

## Installation

Install the library and its depenencies via [OPAM][opam]:

[opam]: http://opam.ocaml.org/

```bash
opam install dispatch
```

## Development

To install development versions of the library, pin the package from the root
of the repository:

```bash
opam pin add .
```

You can install the latest changes by commiting them to the local git
repository and running:

```bash
opam upgrade dispatch
```

For building and running the tests during development, you will need to install
the `oUnit` package and reconfigure the build process to enable tests:

```bash
opam install oUnit
./configure --enable-tests
make && make test
```

## Usage

Dispatch is designed to work with whatever sort of handler you care to use,
whether it's synchronous, Lwt-based, or Async-based. Here's a simple example of
using the `Dispatch.DSL` module to setup routing for a "Hello, World!" server.
The example assumes a `Server` module and `request` type, and that handlers
should return strings that will be interpreted as the body of the response.

```ocaml
open Dispatch

let hello_handler keys rest request =
  let who = try List.assoc "who" keys with Not_found -> "World" in
  Printf.sprintf "Hello, %s!" who
;;

let handler request =
  let table = [
      "/"           , hello_handler
    ; "/hello/:who/", hello_handler
  ] in
  match DSL.dispatch table request.path with
  | Result.Ok handler -> handler request
  | Result.Error _    -> "Not found!"
;;

let _ =
  Server.start handler
```

## License

BSD3, see LICENSE file for its text.
