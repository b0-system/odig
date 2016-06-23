(*---------------------------------------------------------------------------
   Copyright (c) 2016 Daniel C. Bünzli. All rights reserved.
   Distributed under the ISC license, see terms at the end of the file.
   %%NAME%% %%VERSION%%
  ---------------------------------------------------------------------------*)

(* Generator *)

type gen = { edgeop : string; b : Buffer.t }
type k = gen -> unit

let addc c g = Buffer.add_char g.b c
let adds s g = Buffer.add_string g.b s
let adds_id s g = (* escape quotes *)
  let len = String.length s in
  let max_idx = len - 1 in
  let flush b start i =
    if start < len then Buffer.add_substring b s start (i - start);
  in
  let rec loop start i =
    if i > max_idx then flush g.b start i else
    match String.get s i with
    | '\"' -> flush g.b start i; adds "\"" g; loop (i + 1) (i + 1)
    | c -> loop start (i + 1)
  in
  addc '"' g; loop 0 0; addc '"' g

(* Generation sequences. *)

type 'a seq = gen -> unit
let empty g = ()
let ( ++ ) s s' g = s g; s' g; ()

(* Graph *)

type id = string
type st
type att
type t = (gen -> unit) * string

let alist a g = match a with None -> () | Some a -> addc '[' g; a g; addc ']' g

let edge ?atts:a id id' g =
  adds_id id g; adds g.edgeop g; adds_id id' g; alist a g; adds ";\n" g

let node ?atts:a id g = adds_id id g; alist a g; adds ";\n" g

let atts k atts g =
  let kind = match k with
  | `Graph -> "graph "
  | `Node -> "node "
  | `Edge -> "edge "
  in
  adds kind g; alist (Some atts) g; adds ";\n" g

let att a v g = adds_id a g; addc '=' g; adds_id v g
let label = att "label"
let color = att "color"
let subgraph ?id sts g =
  let id = match id with None -> empty | Some id -> adds_id id in
  adds "subgraph" g; id g; adds "{\n" g; sts g; adds "}\n" g

let graph ?id ?(strict = false) g sts =
  let strict = if strict then adds "strict " else empty in
  let kind, edgeop = match g with
  | `Graph -> adds "graph ", "--"
  | `Digraph -> adds "digraph ", "->"
  in
  let id = match id with None -> empty | Some id -> adds_id id ++ addc ' ' in
  (fun g -> strict g; kind g; id g; adds "{\n" g; sts g; adds "}\n" g),
  edgeop

(* Output *)

let buffer_add b (g, edgeop) = g { edgeop; b }

let kbuf k g =
  let b = Buffer.create 65525 in
  buffer_add b g;
  k b

let to_string g = kbuf Buffer.contents g
let output oc g = kbuf (fun b -> Buffer.output_buffer oc b) g

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
