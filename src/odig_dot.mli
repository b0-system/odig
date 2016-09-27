(*---------------------------------------------------------------------------
   Copyright (c) 2016 Daniel C. Bünzli. All rights reserved.
   Distributed under the ISC license, see terms at the end of the file.
   %%NAME%% %%VERSION%%
  ---------------------------------------------------------------------------*)

(** Dot graph generator.

    See {!Odig.Private.Dot}. *)

type 'a seq
val empty : 'a seq
val ( ++ ) : 'a seq -> 'a seq -> 'a seq

type id = string
type st
type att
type t

val edge : ?atts:att seq -> id -> id -> st seq
val node : ?atts:att seq -> id -> st seq
val atts : [`Graph | `Node | `Edge] -> att seq -> st seq
val att : string -> string -> att seq
val label : string -> att seq
val color : string -> att seq
val subgraph : ?id:id -> st seq -> st seq
val graph :
  ?id:id -> ?strict:bool -> [`Graph | `Digraph] -> st seq -> t

val buffer_add : Buffer.t -> t -> unit
val to_string : t -> string
val output : out_channel -> t -> unit

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
