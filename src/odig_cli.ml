(*---------------------------------------------------------------------------
   Copyright (c) 2016 Daniel C. Bünzli. All rights reserved.
   Distributed under the ISC license, see terms at the end of the file.
   %%NAME%% %%VERSION%%
  ---------------------------------------------------------------------------*)

open Bos_setup
open Cmdliner

let path_arg =
  let parse s = match Fpath.of_string s with
  | Error (`Msg m) -> `Error m
  | Ok p -> `Ok p
  in
  parse, Fpath.pp

(* Command lines *)

let conf ?docs () =
  let conf_file =
    let doc = "Use $(docv) as the odig configuration file. See odig-conf(7)."in
    let env = Arg.env_var "OPKG_CONF" in
    Arg.(value & opt path_arg Odig.Conf.default_file & info ["C"; "conf" ]
           ~env ~doc ~docv:"FILE" ?docs)
  in
  let conf conf_file = match Odig.Conf.of_file conf_file with
  | Ok v -> `Ok v
  | Error (`Msg e) -> `Error (false, e)
  in
  Term.(ret (const conf $ conf_file))

(*---------------------------------------------------------------------------
   Copyright (c) 2016 Daniel C. Bünzli

   Permission to use, copy, modify, and/or distribute this software for any
   purpose with or without fee is hereby granted, provided that the above
   copyright notice and this permission notice appear in all copies.

   THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
   WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
   MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
   ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
   WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
   ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
   OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
  ---------------------------------------------------------------------------*)
