(*---------------------------------------------------------------------------
   Copyright (c) 2016 The odig programmers. All rights reserved.
   Distributed under the ISC license, see terms at the end of the file.
   %%NAME%% %%VERSION%%
  ---------------------------------------------------------------------------*)

open Bos_setup

(* Generator *)

type gen = { b : Buffer.t }
type k = gen -> unit

let addc c g = Buffer.add_char g.b c
let adds s g = Buffer.add_string g.b s
let adds_esc s g =
  (* N.B. we also escape @'s since ocamldoc trips over them. *)
  let len = String.length s in
  let max_idx = len - 1 in
  let flush b start i =
    if start < len then Buffer.add_substring b s start (i - start);
  in
  let rec loop start i =
    if i > max_idx then flush g.b start i else
    let next = i + 1 in
    match String.get s i with
    | '&' -> flush g.b start i; adds "&amp;" g; loop next next
    | '<' -> flush g.b start i; adds "&lt;" g; loop next next
    | '>' -> flush g.b start i; adds "&gt;" g; loop next next
    | '\'' -> flush g.b start i; adds "&apos;" g; loop next next
    | '\"' -> flush g.b start i; adds "&quot;" g; loop next next
    | '@' -> flush g.b start i; adds "&commat;" g; loop next next
    | c -> loop start next
  in
  loop 0 0

(* Generation sequences *)

type 'a seq = k
let empty b = ()
let ( ++ ) g g' b = g b; g' b; ()
let list e l = List.fold_left (fun acc v -> acc ++ e v) empty l

(* HTML values. *)

type attv
type att
type cont
type t = k

let attv = adds_esc
let att k v g = adds k g; adds "=\"" g; v g; addc '\"' g; ()
let data = adds_esc
let el el ?atts content g = (* not T.R. *)
  let atts = match atts with
  | None -> empty | Some a -> fun g -> addc ' ' g; a g
  in
  addc '<' g; adds el g; atts g; addc '>' g;
  content g;
  adds "</" g; adds el g; addc '>' g;
  ()

(* Derived attributes *)

let href l = att "href" (attv l)
let class_ l = att "class" (attv l)
let id i = att "id" (attv i)

(* Derived elements. *)

let list el l g = List.iter (fun e -> el e g) l

let a = el "a"
let link ?(atts = empty) l = a ~atts:(href l ++ atts)
let div = el "div"
let meta = el "meta"

let nav = el "nav"
let code = el "code"
let ul = el "ul"
let ol = el "ol"
let li = el "li"
let dl = el "dl"
let dt = el "dt"
let dd = el "dd"
let p = el "p"
let header = el "header"
let h1 = el "h1"
let h2 = el "h2"
let h3 = el "h3"
let span = el "span"
let body = el "body"
let html = el "html"
let table = el "table"
let tr = el "tr"
let td = el "td"

(* Output *)

let doc_type h = adds "<!DOCTYPE html>\n"
let doc_typify do_it h = if do_it then doc_type ++ h else h

let buffer_add ?(doc_type = true) b h = (doc_typify doc_type h) { b }

let kbuf ?doc_type k h =
  let b = Buffer.create 65525 in
  buffer_add ?doc_type b h;
  k b

let to_string ?doc_type h = kbuf ?doc_type Buffer.contents h
let output ?doc_type oc h =
  kbuf ?doc_type (fun b -> Buffer.output_buffer oc b) h

(*---------------------------------------------------------------------------
   Copyright (c) 2016 The odig programmers

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
