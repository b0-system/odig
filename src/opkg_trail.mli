(*---------------------------------------------------------------------------
   Copyright (c) 2016 Daniel C. Bünzli. All rights reserved.
   Distributed under the ISC license, see terms at the end of the file.
   %%NAME%% %%VERSION%%
  ---------------------------------------------------------------------------*)

(** Computation trails.

    See {Opkg.Trail} *)

open Bos_setup

(** Signature for a trail universe *)
module type S = sig

  type status = [ `Fresh | `Stale ]
  (** The type for statuses. *)

  type t
  (** The type for trails. *)

  val v : id:string -> t
  (** [v id] is the trail with id [id] in the universe. *)

  val id : t -> string
  (** [id t] is [t]'s id. *)

  val preds : t -> t list
  (** [preds t] is the list of trails preceeding [t]. *)

  val succs : t -> t list
  (** [succs t] is the list of trails succeeding [t]. *)

  val witness : t -> Opkg_digest.t option
  (** [witness t] is [t]'s last witness. *)

  val status : t -> status
  (** [status t] is [t]'s status. *)

  val set_witness :
    ?succs:[`Delete | `Stale | `Nop] -> ?preds:t list -> t ->
    Digest.t option -> unit
  (** [set ~succs ~preds t d] sets [t] to digest [d] with predecessors [preds].
      If [d] is different from [digest t] and [succs] is [`Stale] (default) all
      recursive successors of [t] are marked as stale, if [succs] is [`Delete]
      they are deleted and if it is [`Nop] they are left untouched. *)

  val delete : ?succs:[`Delete | `Stale | `Nop] -> t -> unit
  (** [delete ~succs t] deletes [t] from its context. If [succs] is
      [`Delete] (default) all recursive successors of [t] are also deleted,
      if [succ] is `[Stale] they are marked as stale and if it is [`Nop] they
      are left untouched except for their predecessor set. *)

  val pp_dot : root:Fpath.t -> t Fmt.t

  (** {1 Predicates and comparison} *)

  val equal : t -> t -> bool
  (** [equal t t'] is [true] iff [t] and [t'] have the same [id]. *)

  val compare : t -> t -> int
  (** [compare t t'] totally orders [t] and [t'] using their [id]. *)

  (** {1 Universe} *)

  val universe : unit -> t list
  (** [universe ()] are all the trails in the universe. *)

  val read : ?create:bool -> Fpath.t -> (unit, R.msg) result
  (** [read ~create f] reads a universe from [f]. If [f] doesn't exist
      the universe is empty if [create] is [true] (default)
      or errors if [create] is [false]. *)

  val write : Fpath.t -> (unit, R.msg) result
  (** [write f] writes the universe to [f]. *)

  val pp_dot_universe : root:Fpath.t -> unit Fmt.t
end

module Make () : S
(** [Make ()] is a new universe of trails. *)

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
