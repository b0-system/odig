(*---------------------------------------------------------------------------
   Copyright (c) 2016 Daniel C. Bünzli. All rights reserved.
   Distributed under the ISC license, see terms at the end of the file.
   %%NAME%% %%VERSION%%
  ---------------------------------------------------------------------------*)

open Rresult

val assume_inc : Fpath.t -> unit
val assume_obj : Fpath.t -> unit

val load_libs :
  ?force:bool -> ?deps:bool -> ?init:bool -> ?dir:Fpath.t -> unit -> unit

val load :
  ?force:bool -> ?deps:bool -> ?init:bool -> ?dir:Fpath.t -> string -> unit

val load_pkg :
  ?silent:bool -> ?force:bool -> ?deps:bool -> ?init:bool -> string -> unit

val init : ?conf:Odig_conf.t -> unit -> unit
val announce : unit -> unit
val reset : unit -> unit
val status : unit -> unit
val help : unit -> unit
val debug : unit -> unit

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
