(*---------------------------------------------------------------------------
   Copyright (c) 2016 Daniel C. Bünzli. All rights reserved.
   Distributed under the ISC license, see terms at the end of the file.
   %%NAME%% %%VERSION%%
  ---------------------------------------------------------------------------*)

(** {!Cmdliner} and common definitions for commands. *)

open Bos_setup
open Cmdliner

(** {1 Manual section for common options} *)

val common_opts : string
(** [common_opts] is the manual section were common options are
    documented. *)

val common_opts_man : Cmdliner.Manpage.block list
(** [common_opts_man] is the manual section for common options. *)

val common_man : Cmdliner.Manpage.block list
(** [common_man] is a manual fragment common to many commands. *)

val see_also_main_man : Cmdliner.Manpage.block list
(** [see_also_main_man] is a "see also" manpage fragment. *)

(** {1 Converters} *)

val path_arg : Fpath.t Arg.converter
(** [path_arg] is a path argument converter. *)

val cmd_arg : Cmd.t Arg.converter
(** [cmd_arg] is a command argument converter. *)

val pkg_name_arg : Odig.Pkg.name Arg.converter
(** [pkg_name_arg] is a command argument for package names. *)

(** {1 Arguments} *)

val loc : bool Term.t
(** [loc] is a [--loc] command line option. *)

val show_pkg : bool Term.t
(** [show_pkg] is a [--show-pkg] command line option. *)

val json : bool Term.t
(** [json] is a [--json] command line option. *)

val no_pager : bool Term.t
(** [no_pager] is a [--no-pager] command line option. *)

val warn_error : bool Term.t
(** [warn_error] is a [--warn-error] command line option that
    turns warnings into error. *)

val odoc : Cmd.t Term.t
(** [odoc] is a [--odoc] command line option for specifying
    [odoc]. *)

val ocamldoc : Cmd.t Term.t
(** [ocamldoc] is a [--ocamldoc] command line option for specifying
    [ocamldoc]. *)

val doc_force : bool Term.t
(** [doc_force] is [--force] command line option for forcing
    doc rebuild. *)

val pkgs : ?right_of:int -> unit -> string list Term.t
(** [pkgs] is a list of packages specified as positional arguments. *)

val pkgs_or_all : [`Pkgs of Odig.Pkg.name list | `All ] Term.t
(** [pkgs_or_all] is like {!pkgs} except if no package is specified all
    of them is implied. *)

val pkgs_or_all_opt : [`Pkgs of Odig.Pkg.name list | `All ] Term.t
(** [pkgs_or_all] is like {!pkgs_or_all} except all packages are only
    provided if [--all] is specified. It is an error if no package
    is specified and [--all] is absent. *)

(** {1 Commonalities} *)

val setup : unit -> Odig.Conf.t Term.t
(** [setup ()] defines a basic setup common to all commands. This
    includes, by side effect, setting log verbosity for {!Logs},
    ajusting colored output and finally getting a configuration
    through {!Odig_cli.conf}. *)

val lookup_pkgs :
  Odig.Conf.t -> [`Pkgs of Odig.Pkg.name list | `All ] ->
  (Odig.Pkg.set, Bos_setup.R.msg) Result.result
(** [lookup_pkgs conf names] lookups packages [names] in [conf]. *)

(** {1 Error handling} *)

val handle_error : (int, [ `Msg of string]) result -> int
(** [handle_error r] is [r]'s result or logs [r]'s error and returns 3. *)

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
