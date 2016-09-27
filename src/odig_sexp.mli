(*---------------------------------------------------------------------------
   Copyright (c) 2016 Daniel C. Bünzli. All rights reserved.
   Distributed under the ISC license, see terms at the end of the file.
   %%NAME%% %%VERSION%%
  ---------------------------------------------------------------------------*)

open Bos_setup

type pos = int
type range = pos * pos
type src = File of Fpath.t
type loc = src * range
val pp_loc : loc Fmt.t

type t = [ `Atom of string | `List of t list ] * loc
val of_string : src:src -> string -> (t list, R.msg) result
val of_file : Fpath.t -> (t list, R.msg) result
val to_file : Fpath.t -> t list -> (unit, R.msg) result

module Codec : sig

  type error = R.msg
  val pp_error : error Fmt.t

  exception Error of error

  type sexp
  type 'a t

  val v : kind:string -> enc:('a -> sexp) -> dec:(sexp -> 'a) -> 'a t

  val enc : 'a t -> 'a -> sexp
  val dec : 'a t -> sexp -> 'a
  val dec_result : 'a t -> sexp -> ('a, error) result

  val with_kind : string -> 'a t -> 'a t
  val write : Fpath.t -> 'a t -> 'a -> (unit, R.msg) result
  val read : Fpath.t -> 'a t -> ('a, R.msg) result

  (** {1:base Base type codecs} *)

  val unit : unit t
  val const : 'a -> 'a t
  val bool : bool t
  val int : int t
  val string : string t
  val option : 'a t -> 'a option t
  val result : ok:'a t -> error:'b t -> ('a, 'b) result t
  val list : 'a t -> 'a list t
  val pair : 'a t -> 'b t -> ('a * 'b) t
  val t2 : 'a t -> 'b t -> ('a * 'b) t
  val t3 : 'a t -> 'b t -> 'c t -> ('a * 'b * 'c) t
  val t4 : 'a t -> 'b t -> 'c t -> 'd t -> ('a * 'b * 'c * 'd) t
  val t5 : 'a t -> 'b t -> 'c t -> 'd t -> 'e t -> ('a * 'b * 'c * 'd * 'e) t

(*
  type case_enc =  E : string * 'b t
  type 'a case = C : string * 'b t * ('b -> 'a)
  val variant : enc:('a -> case_enc) -> dec:'a case list -> 'a t
*)

  val view : ?kind:string -> ('a -> 'b) * ('b -> 'a) -> 'b t -> 'a t
end

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
