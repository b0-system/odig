WS
==

## Websocket Implementation for OCaml
### (Server only, client coming soon)


The following is an example for getting set websockets set up with cohttp + Lwt. Note that this example requires `cohttp >= v2.0` *which is unreleased (as of writing)*, but you can pull and pin the master branch with:
```
$ git clone git@github.com:mirage/ocaml-cohttp.git
$ opam pin ocaml-cohttp
```

Also the example depends on `interface-prime-lwt`:
```
$ opam install interface-prime-lwt
```

The example is also contained in `example/example_server.ml`.

**Example:**
```ocaml
open Lwt
open Cohttp
open Cohttp_lwt_unix

module Websocket = Ws.Make(Interface'_lwt.Io)

let respond ?headers status message =
  let len = String.length message |> Int64.of_int in
  let res_f = Response.make ~encoding:(Transfer.Fixed len) ~status in
  let res = match headers with
      | Some headers -> res_f ~headers:(headers |> Header.of_list) ()
      | None -> res_f () in
    (res, fun _ oc -> Lwt_io.write oc message) |> return

let ws_handler send =
  Some "Welcome to my websocket!" |> send
  >>= fun _ ->
  return (function
    | Some m -> Lwt_io.printf "Received message: %s\n" m
      >>= fun _ -> Some (Printf.sprintf "Thanks, I got [%s]" m) |> send
    | None -> Lwt_io.printf "Connection closed\n")

let server =
  let callback _conn req _body =
    let meth = req |> Request.meth in
    let headers = req |> Request.headers |> Header.to_list in
    match meth with
      | `GET ->
          (if Ws.is_websocket_upgrade headers then
            match Websocket.upgrade headers with
              | Error e_headers ->
                let res = Response.make ~encoding:(Transfer.Unknown) ~status:`Bad_request ~headers:(e_headers |> Header.of_list) () in
                (res, fun _ _ -> return_unit) |> return
              | Ok ok_headers ->
                let res = Response.make ~encoding:(Transfer.Unknown) ~status:`Switching_protocols ~headers:(ok_headers |> Header.of_list) () in
                (res, fun ic oc -> Websocket.handle_server ws_handler ic oc) |> return
          else
            respond `Bad_request "")
      | _ ->
        respond `Method_not_allowed "Only websocket protocol supported!"
  in
    Server.create ~mode:(`TCP (`Port 8000)) (Server.make_expert ~callback ())

let () = ignore (Lwt_main.run server)
```
