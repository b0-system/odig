(*---------------------------------------------------------------------------
   Copyright (c) 2016 Daniel C. Bünzli. All rights reserved.
   Distributed under the ISC license, see terms at the end of the file.
   %%NAME%% %%VERSION%%
  ---------------------------------------------------------------------------*)

open Bos_setup

include Digest

let file f =
  try Ok (file @@ Fpath.to_string f)
  with Sys_error e -> R.error_msgf "%a: %s" Fpath.pp f e

external caml_string_set_64 :
  bytes -> int -> int64 -> unit = "%caml_string_set64"

let mtime_to_string m =
  let b = Bytes.create 8 in
  caml_string_set_64 b 0 (Int64.bits_of_float m);
  Bytes.unsafe_to_string b

let mtimes paths =
  try
    let add_mtime acc p = match OS.Path.stat p with
    | Ok s -> (mtime_to_string s.Unix.st_mtime :: acc)
    | Error (`Msg m) -> failwith m
    in
    let paths = List.sort Fpath.compare paths in
    let mtimes = List.fold_left add_mtime [] paths in
    Ok (Digest.string @@ String.concat mtimes)
  with Failure e -> R.error_msg e

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
