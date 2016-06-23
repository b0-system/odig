(*---------------------------------------------------------------------------
   Copyright (c) 2016 Daniel C. Bünzli. All rights reserved.
   Distributed under the ISC license, see terms at the end of the file.
   %%NAME%% %%VERSION%%
  ---------------------------------------------------------------------------*)

open Bos_setup

type 'a t = unit

let v () = ()

let magic = "opkg-%%VERSION%%-ocaml-" ^ Sys.ocaml_version

let write : type a. a t -> Fpath.t -> a -> (unit, R.msg) result =
fun codec f v  ->
  let write oc v =
    try
      output_string oc magic;
      output_value oc v;
      flush oc;
      Ok ()
    with Sys_error e -> R.error_msgf "%a: %s" Fpath.pp f e
  in
  R.join @@ OS.File.with_oc f write v

let read : type a. a t -> Fpath.t -> (a, R.msg) result =
fun codec f ->
  let read ic () =
    let m = really_input_string ic (String.length magic) in
    match m = magic with
    | true -> Ok (input_value ic : a)
    | false ->
        R.error_msgf "%a: invalid magic number %S, expected %S"
          Fpath.pp f m magic
  in
  R.join @@ OS.File.with_ic f read ()


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
