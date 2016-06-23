(*---------------------------------------------------------------------------
   Copyright (c) 2016 Daniel C. Bünzli. All rights reserved.
   Distributed under the ISC license, see terms at the end of the file.
   %%NAME%% %%VERSION%%
  ---------------------------------------------------------------------------*)

(** HTML generation.

    See {!Opkg.Html}. *)

type 'a seq
val empty : 'a seq
val ( ++ ) : 'a seq -> 'a seq -> 'a seq

type att
type attv
type t

val attv : string -> attv seq
val att : string -> attv seq -> att seq
val data : string -> t seq
val el : string -> ?atts:att seq -> t seq -> t seq
val html : ?atts:att seq -> t seq -> t

val href : string -> att seq
val id : string -> att seq
val class_ : string -> att seq

val a : ?atts:att seq -> t seq -> t seq
val link : ?atts:att seq -> string -> t seq -> t seq
val div : ?atts:att seq -> t seq -> t seq
val meta : ?atts:att seq -> t seq -> t seq
val nav : ?atts:att seq -> t seq -> t seq
val code : ?atts:att seq -> t seq -> t seq
val ul : ?atts:att seq -> t seq -> t seq
val ol : ?atts:att seq -> t seq -> t seq
val li : ?atts:att seq -> t seq -> t seq
val dl : ?atts:att seq -> t seq -> t seq
val dt : ?atts:att seq -> t seq -> t seq
val dd : ?atts:att seq -> t seq -> t seq
val p : ?atts:att seq -> t seq -> t seq
val h1 : ?atts:att seq -> t seq -> t seq
val h2 : ?atts:att seq -> t seq -> t seq
val span : ?atts:att seq -> t seq -> t seq
val body : ?atts:att seq -> t seq -> t seq
val html : ?atts:att seq -> t seq -> t seq

val buffer_add : ?doc_type:bool -> Buffer.t -> t seq -> unit
val to_string : ?doc_type:bool -> t seq -> string
val output : ?doc_type:bool -> out_channel -> t seq -> unit

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
