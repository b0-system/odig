(*---------------------------------------------------------------------------
   Copyright (c) 2016 Daniel C. Bünzli. All rights reserved.
   Distributed under the ISC license, see terms at the end of the file.
   %%NAME%% %%VERSION%%
  ---------------------------------------------------------------------------*)

open Astring

(* Generator *)

type gen = { mutable sep : bool; b : Buffer.t }
type k = gen -> unit

let addc c g = Buffer.add_char g.b c
let adds s g = Buffer.add_string g.b s
let adds_esc s g =
  let len = String.length s in
  let max_idx = len - 1 in
  let flush b start i =
    if start < len then Buffer.add_substring b s start (i - start);
  in
  let rec loop start i = match i > max_idx with
  | true -> flush g.b start i
  | false ->
      let next = i + 1 in
      match String.get s i with
      | '"' -> flush g.b start i; adds "\\\"" g; loop next next
      | '\\' -> flush g.b start i; adds "\\\\" g; loop next next
      | c when Char.Ascii.is_control c ->
          flush g.b start i; adds (strf "\\u%04X" (Char.to_int c)) g;
          loop next next
      | c -> loop start next
  in
  loop 0 0

(* Generation sequences. *)

type 'a seq = k
let empty g = ()
let ( ++ ) s s' g = s g; s' g; ()

(* JSON values. *)

type t = k
type mem
type el

let null g = adds "null" g
let bool b g = match b with true -> adds "true" g | false -> adds "false" g
let int i g = adds (string_of_int i) g
let str s g = addc '"' g; adds_esc s g; addc '"' g

let nosep g = g.sep <- false
let sep g = g.sep
let set_sep sep g = g.sep <- sep
let if_sep g = if not g.sep then g.sep <- true else addc ',' g

let el e g = if_sep g; e g
let el_if c v = if c then el (v ()) else empty
let arr seq g = (* Not T.R. *)
  let sep = sep g in
  addc '[' g; nosep g; seq g; addc ']' g; set_sep sep g

let mem m v g = if_sep g; str m g; addc ':' g; v g
let mem_if c m v = if c then mem m (v ()) else empty
let obj mems g = (* Not T.R. *)
  let sep = sep g in
  addc '{' g; nosep g; mems g; addc '}' g; set_sep sep g

(* Output *)

let buffer_add b j = j { sep = true; b }

let kbuf k j =
  let b = Buffer.create 65525 in
  buffer_add b j;
  k b

let to_string j = kbuf Buffer.contents j
let output oc j = kbuf (fun b -> Buffer.output_buffer oc b) j

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
