(*---------------------------------------------------------------------------
   Copyright (c) 2018 The odig programmers. All rights reserved.
   Distributed under the ISC license, see terms at the end of the file.
   %%NAME%% %%VERSION%%
  ---------------------------------------------------------------------------*)

(** [Odig] support library.

    This library is used to implement the [odig] tool. *)

(** {1:support Odig support} *)

open B0_std
open B00

(** Digests. *)
module Digest : sig
  include (module type of Digest)

  val pp : Format.formatter -> t -> unit
  (** [pp] formats digests. *)

  val pp_opt : Format.formatter -> t option -> unit
  (** [pp_opt] formats optional digests. *)

  (** Digest sets. *)
  module Set : Set.S with type elt = t

  (** Digest maps. *)
  module Map : Map.S with type key = t
end

(** Packages *)
module Pkg : sig

  (** {1:pkgs Packages} *)

  type name = string
  (** The type for package names. *)

  type t
  (** The type for packages. *)

  val name : t -> name
  (** [name] is the name of the package. *)

  val path : t -> Fpath.t
  (** [path] is the path to the compilation objects of the package. *)

  val equal : t -> t -> bool
  (** [equal p0 p1] is [true] if [p0] and [p1] point to the same package. *)

  val compare : t -> t -> int
  (** [compare p0 p1] is a total order on packages compatible with {!equal}. *)

  val compare_by_caseless_name : t -> t -> int
  (** [compare_by_caseless_name p0 p1] compares [p0] and [p1] by
      name in a caseless manner. *)

  val pp : t Fmt.t
  (** [pp] formats packages. *)

  val pp_name : t Fmt.t
  (** [pp_name] formats package names. *)

  val pp_version : string Fmt.t
  (** [pp_version] formats a package version. *)

  (** Package identifier sets. *)
  module Set : Set.S with type elt = t

  (** Package identifier maps. *)
  module Map : Map.S with type key = t

  (** {1:query Queries} *)

  val of_dir : Fpath.t -> t list
  (** [of_dir lib_dir] are the packages found in [lib_dir]. This is
      simply all the directory names inside [lib_dir] and an [ocaml]
      package which points to [ocamlc -where]. *)

  val by_names : ?init:t String.Map.t -> t list -> t String.Map.t
  (** [by_names pkgs] indexes [pkgs] by module name and adds them to
      [init] (defaults to {!String.Map.empty}. *)
end

(** Lookup package API documention compilation objects.

    The compilation objects relevant for documentation are looked up
    according to the following rules:
    {ol
    {- Packages denote which compilation units should appear in the
       docs by installing their [cmi] file.}
    {- For each of these files odig looks, in the same directory,
       first for a corresponding [cmti] file then if missing for a
       [cmt] file, then if none of these exist the [cmi] file.}
    {- For [cmti] or [cmt] files which have no corresponding [cmi] file
       odig collects them and deems them to be hidden ([odoc] will be
       called with the [--hidden] option).}} *)
module Doc_cobj : sig

  (** {1:doc_cobj Documentation compilation objects} *)

  type kind = Cmi | Cmti | Cmt (** *)
  (** The type for kinds of documentation compilation object. *)

  type t
  (** The type for documentation compilation objects. *)

  val path : t -> Fpath.t
  (** [path cobj] is the path to [cobj]. *)

  val kind : t -> kind
  (** [kind cobj] is the kind of [cobj]. *)

  val modname : t -> string
  (** [modname cobj] is the module name of [cobj] (as determined
      from the filename). *)

  val pkg : t -> Pkg.t
  (** [pkg cobj] is the package of [cobj]. *)

  val hidden : t -> bool
  (** [hidden cobj] is [true] if odoc must compile [cobj] with
      the [--hidden] option. *)

  val don't_list : t -> bool
  (** [don't_list cobj] is [true] if [cobj] should not appear
      in module indexes. *)

  (** {1:query Queries} *)

  val of_pkg : Pkg.t -> t list
  (** [of_pkg pkg] are the compilation objects of [pkg] that are
      useful for documentation generation. *)

  val by_modname : ?init:t list String.Map.t -> t list -> t list String.Map.t
  (** [by_modname ~init cobjs] indexes [cobjs] by module name
      and adds them to [init] (defaults to {!String.Map.empty}). *)
end

(** Lookup package opam metadata. *)
module Opam : sig

  (** {1:opam opam metadata} *)

  type t
  (** The type for opam metadata. *)

  val authors : t -> string list
  (** [authors i] is the [authors:] field. *)

  val bug_reports : t -> string list
  (** [bug_reports i] is the [bug-reports:] field. *)

  val depends : t -> string list
  (** [depends i] is the [depends:] field. *)

  val dev_repo : t -> string list
  (** [dev_repo i] is the [dev-repo:] field. *)

  val doc : t -> string list
  (** [doc i] is the [doc:] field. *)

  val homepage : t -> string list
  (** [homepage i] is the [homepage:] field. *)

  val license : t -> string list
  (** [license i] is the [license:] field. *)

  val maintainer : t -> string list
  (** [maintainer i] is the [maintainer:] field. *)

  val synopsis : t -> string
  (** [synopsis i] is the [synopsis:] field. *)

  val tags : t -> string list
  (** [info_tags i] are the package's tags. *)

  val version : t -> string
  (** [version i] is the package's version. *)

  (** {1:query Queries} *)

  val file : Pkg.t -> Fpath.t option
  (** [file pkg] is the opam file of package [pkg] (if any). *)

  val query : Pkg.t list -> (Pkg.t * t) list
  (** [query pkgs] queries the opam files associated to
      the given packages (if any).

      {b Note.} It is better to batch queries, [opam show] is
      quite {{:https://github.com/ocaml/opam/issues/3721}slow}
      (at least until v2.0.3). *)
end

(** Lookup package documentation directory. *)
module Doc_dir : sig

  (** {1:doc_dir Package documentation directory} *)

  type t
  (** The type for documentation directory information. *)

  val dir : t -> Fpath.t option
  (** [dir] is the path to the documentation directory (if any). *)

  val changes_files : t -> Fpath.t list
  (** [changes_files i] are the package's change log files. *)

  val license_files : t -> Fpath.t list
  (** [license_files i] are the package's licenses files. *)

  val odoc_pages : t -> Fpath.t list
  (** [odoc_pages i] are the package's [odoc] pages *)

  val odoc_assets_dir : t -> Fpath.t option
  (** [odoc_assets i] is the package's [odoc] assets directory (if any). *)

  val odoc_assets : t -> Fpath.t list
  (** [odoc_assets i] is the package's [odoc] assets directory contents. *)

  val readme_files : t -> Fpath.t list
  (** [readme_files i] are the package's readme files. *)

  (** {1:query Queries} *)

  val of_pkg : doc_dir:Fpath.t -> Pkg.t -> t
  (** [query ~doc_dir pkg] queries the documentation directory [doc_dir]
      for documentation about [pkg]. *)
end

(** Gather package information

    Gathers {!Doc_cobj}, {!Opam} and {!Docdir} information about
    a package. *)
module Pkg_info : sig

  (** {1:pkg_info Package info} *)

  type t
  (** The type for package information. *)

  val doc_cobjs : t -> Doc_cobj.t list
  (** [doc_cobjs i] are the documentation compilation objects of [i]. *)

  val doc_dir : t -> Doc_dir.t
  (** [doc_dir i] is the doc dir information of [i]. *)

  val opam : t -> Opam.t
  (** [opam i] is the opam information of [i]. *)

  (** {1:field Uniform field access}

      Access information as list of strings. *)

  type field =
  [ `Authors | `Changes_files | `Depends | `Doc_cobjs | `Homepage | `Issues
  | `License | `License_files | `Maintainers | `Odoc_assets | `Odoc_pages
  | `Online_doc | `Readme_files | `Repo | `Synopsis | `Tags | `Version ]
  (** The type for fields. *)

  val field_names : (string * field) list
  (** [field_names] associated a string name to each field. *)

  val get : field -> t -> string list
  (** [get field i] is the field [field] of [i] as a list of strings. *)

  val pp : t Fmt.t
  (** [pp] formats all package information fields in alphabetic order. *)

  (** {1:query Queries} *)

  val query : doc_dir:Fpath.t -> Pkg.t list -> (Pkg.t * t) list
  (** [query ~doc_dir pkgs] combines the result of
      {!Doc_cobj.of_pkg}, {!Opam.query} and {!Doc_dir.of_pkg}. *)
end

(** Odig configuration. *)
module Conf : sig

  (** {1:conf Configuration} *)

  type t
  (** The type for configuration. *)

  val v :
    b0_cache_dir:Fpath.t option -> b0_log_file:Fpath.t option ->
    cache_dir:Fpath.t option -> doc_dir:Fpath.t option ->
    lib_dir:Fpath.t option -> max_spawn:int option ->
    odoc_theme:B0_odoc.Theme.name option -> share_dir:Fpath.t option ->
    unit -> (t, string) result
  (** [v] consructs a configuration with given attributes. If unspecified
      they are discovered in various ways. *)

  val b0_cache_dir : t -> Fpath.t
  (** [b0_cache_dir c] is [c]'s b0 cache directory. *)

  val b0_log_file : t -> Fpath.t
  (** [b0_log_file c] is [c]'s b0 log file. *)

  val cache_dir : t -> Fpath.t
  (** [cache_dir c] is [c]'s cache directory. *)

  val doc_dir : t -> Fpath.t
  (** [doc_dir c] is [c]'s documentation directory. *)

  val lib_dir : t -> Fpath.t
  (** [lib_dir c] is [c]'s library directory. *)

  val html_dir : t -> Fpath.t
  (** [html_dir c] is [c]'s HTML directory, where the API docs
      are generated (derived from {!cache_dir}). *)

  val odoc_theme : t -> string
  (** [odoc_theme c] is [c]'s odoc theme to use. *)

  val max_spawn : t -> int
  (** [max_spawn c] maximum number of spawns. *)

  val memo : t -> (Memo.t, string) result
  (** [memo conf] is a memoizer for configuration [conf]. *)

  val pkgs : t -> Pkg.t list
  (** [pkgs conf] are the packages of configuration [conf]. *)

  val pkg_infos : t -> Pkg_info.t Pkg.Map.t
  (** [pkg_infos conf] are the package information of {!pkgs}. *)

  val share_dir : t -> Fpath.t
  (** [share_dir c] is [c]'s share directory. *)

  val pp : t Fmt.t
  (** [pp] formats configurations. *)

  (** {1:env Environment variables} *)

  val cache_dir_env : string
  (** [cache_dir_env] is the environment variable that can be used to
      define the odig cache directory. *)

  val lib_dir_env : string
  (** [lib_dir_env] is the environment variable that can be used to
      define a lib dir. *)

  val doc_dir_env : string
  (** [doc_dir_env] is the environment variable that can be used to
      define a doc dir. *)

  val share_dir_env : string
  (** [share_dir_env] is the environment variable that can be used to
      define a share dir. *)

  val odoc_theme_env : string
  (** [odoc_theme_env] is the environment variable that can be used
      to define the default odoc theme. *)
end

(*---------------------------------------------------------------------------
   Copyright (c) 2018 The odig programmers

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
