(*---------------------------------------------------------------------------
   Copyright (c) 2016 The odig programmers. All rights reserved.
   Distributed under the ISC license, see terms at the end of the file.
   %%NAME%% %%VERSION%%
  ---------------------------------------------------------------------------*)

(** OCaml compilation artefacts readers.

    Segregates our use of OCaml's [compiler-lib].

    {b Dependencies.} AFAIR the digest for a dependency
    is missing when the dependency is introduced by a module alias
    and the artefact is generated with the [-no-alias-deps] option. *)

open Bos_setup

(** {1 Cmi files} *)

type cmi
(** The type for cmi files. *)

val read_cmi : Fpath.t -> (cmi, R.msg) result
(** [read_cmi f] reads a cmi file from [f]. *)

val cmi_name : cmi -> string
(** [cmi_name cmi] is the interface name of [cmi]. *)

val cmi_digest : cmi -> Digest.t
(** [cmi_digest cmi] is the digest of [cmi]. *)

val cmi_deps : cmi -> (string * Digest.t option) list
(** [cmi_deps cmi] are the interfaces [cmi] depends on; without
    itself. *)

(** {1 Cmti files} *)

type cmti
(** The type for cmti files. *)

val read_cmti : Fpath.t -> (cmti, R.msg) result
(** [read_cmti f] reads a cmti file from [f]. *)

val cmti_name : cmti -> string
(** [cmti_name cmti] is the interface name of [cmti]. *)

val cmti_digest : cmti -> Digest.t
(** [cmti_digest ctmi] is the digest of [cmti]. *)

val cmti_deps : cmti -> (string * Digest.t option) list
(** [cmti_deps cmti] are the interfaces [cmti] depends on; without
    itself. *)

(** {1 Cmo files} *)

type cmo
(** The type for cmo files. *)

val read_cmo : Fpath.t -> (cmo, R.msg) result
(** [read_cmo f] reads a cmo file from [f]. *)

val cmo_name : cmo -> string
(** [cmo_name cmo] is the implementation name of [cmo]. *)

val cmo_cmi_digest : cmo -> Digest.t
(** [cmo_cmi_digest cmo] is the digest of [cmo]'s interface. *)

val cmo_cmi_deps : cmo -> (string * Digest.t option) list
(** [cmo_cmi_deps cmo] are the interfaces [cmo] depends on; without
    itself. *)

(** {1 Cmt files} *)

type cmt
(** The type for cmt files. *)

val read_cmt : Fpath.t -> (cmt, R.msg) result
(** [read_cmt f] reads a cmt file from [f]. *)

val cmt_name : cmt -> string
(** [cmt_name cmt] is the interface name of [cmt]. *)

val cmt_cmi_digest : cmt -> Digest.t
(** [cmt_cmi_digest cmt] is the digest of [cmt]'s interface. *)

val cmt_cmi_deps : cmt -> (string * Digest.t option) list
(** [cmt_cmi_deps cmt] are the interfaces [cmt] depends on; without
    itself. *)

(** {1 Cma files} *)

type cma
(** The type for cma files. *)

val read_cma : Fpath.t -> (cma, R.msg) result
(** [read_cma f] reads a cma ile from [f]. *)

val cma_name : cma -> string
(** [cma_name cma] is the archive name of [cma]. *)

val cma_cmos : cma -> cmo list
(** [cma_cmos cma] are the [cmo]s contained in the archive. *)

val cma_custom : cma -> bool
(** [cma_custom cma] is [true] if it requires custom mode linking. *)

val cma_custom_cobjs : cma -> string list
(** [cma_custom_cobjs] are C objects files needed for custom mode linking. *)

val cma_custom_copts : cma -> string list
(** [cma_custom_copts] are extra options passed for custom mode linking. *)

val cma_dllibs : cma -> string list
(** [cma_dllibs] are dynamically loaded C libraries for ocamlrun dynamic
    linking. *)

(** {1 Cmx files} *)

type cmx
(** The type for cmx files. *)

val read_cmx : Fpath.t -> (cmx, R.msg) result
(** [read_cmx f] reads a cmx file from [f]. *)

val cmx_name : cmx -> string
(** [cmx_name cmx] is the implementation name of [cmx]. *)

val cmx_digest : cmx -> Digest.t
(** [cmx_digest cmx] is the implementation digest of [cmx]. *)

val cmx_cmi_digest : cmx -> Digest.t
(** [cmx_cmi_digest cmx] is the digest of [cmx]'s interface. *)

val cmx_cmi_deps : cmx -> (string * Digest.t option) list
(** [cmx_cmi_deps cmx] are the interfaces [cmx] depends on; without
    itself. *)

val cmx_cmx_deps : cmx -> (string * Digest.t option) list
(** [cmx_cmx_deps cmx] are the implementations [cmx] depends on. *)

(** {1 Cmxa files} *)

type cmxa
(** The type for [cmxa] files *)

val read_cmxa : Fpath.t -> (cmxa, R.msg) result
(** [read_cmxa f] reads a cmxa file from [f]. *)

val cmxa_name : cmxa -> string
(** [cmxa_name cmxa] is the archive name of [cmxa]. *)

val cmxa_cmxs : cmxa -> cmx list
(** [cmxa_cmxs cmxa] are the [cmx]s contained in the archive. *)

val cmxa_cobjs : cmxa -> string list
(** [cmxa_cobjs cmxa] are C objects files needed for linking. *)

val cmxa_copts : cmxa -> string list
(** [cmxa_copts cmxa] are options for the C linker. *)

(** {1 Cmxs files} *)

type cmxs
(** The type for cmxs files *)

val read_cmxs : Fpath.t -> (cmxs, R.msg) result
(** [read_cmxs f] reads a cmxs files from [f].

    {b Warning.} Simply checks the file exists. *)

val cmxs_name : cmxs -> string
(** [cmxs_name cmxs] is the archive name of [cmxx]. *)

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
