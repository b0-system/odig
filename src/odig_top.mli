(*---------------------------------------------------------------------------
   Copyright (c) 2016 Daniel C. Bünzli. All rights reserved.
   Distributed under the ISC license, see terms at the end of the file.
   %%NAME%% %%VERSION%%
  ---------------------------------------------------------------------------*)

(** Toplevel helpers.

    {b Warning.} Proof of concepts do not start using this
    in your scripts.

    {b FIXME.}
    {ul
    {- In general need a mecanism to refine load order (note however
       that e.g. [#load_rec] says the order is unspecified).}
    {- Need a precise description of resolving procedure and
      disambiguisation}} *)

(** {1 Loaders} *)


val load_libs : ?dir:Fpath.t -> unit -> unit
(** [load_libs ~dir ()] loads and setups include directories for
    libraries found in [dir]. [dir] defaults to [Fpath.v "_build"] or
    the value of [ODIG_BUILD_DIR]. *)

(** {1 Init}

    Only call this if you need to setup another configuration.
    Initialisation happens automatically. *)

val init : ?conf:Odig.Conf.t -> unit -> unit
(** [init ~conf ()] initalizes the library with [conf]
    (defaults to {!Odig.Conf.default_file}). *)

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
