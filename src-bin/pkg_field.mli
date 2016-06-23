(*---------------------------------------------------------------------------
   Copyright (c) 2016 Daniel C. Bünzli. All rights reserved.
   Distributed under the ISC license, see terms at the end of the file.
   %%NAME%% %%VERSION%%
  ---------------------------------------------------------------------------*)

open Bos_setup
open Opkg
open Opkg.Private

val lookup :
  warn_error:bool ->
  kind:string ->
  get:(Pkg.t -> ('a, R.msg) result) ->
  undefined:('a -> bool) ->
  Pkg.set -> ((Pkg.t * 'a) list, unit) result

val flatten : rev:bool -> (Pkg.t * 'a list) list -> (Pkg.t * 'a) list

val json_values :
  show_pkg:bool -> mem_n:string -> mem_v:('a -> Json.t) ->
  (Opkg.Pkg.t * 'a) list -> Json.t

val print_values :
  show_pkg:bool -> ('a -> string) ->
  (Opkg.Pkg.t * 'a) list -> unit

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
