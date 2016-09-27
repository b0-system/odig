(*---------------------------------------------------------------------------
   Copyright (c) 2016 Daniel C. Bünzli. All rights reserved.
   Distributed under the ISC license, see terms at the end of the file.
   %%NAME%% %%VERSION%%
  ---------------------------------------------------------------------------*)

(** Mining OCaml package installs.

    {b Warning.} [Odig] is a work in progress. Do not expect these
    APIs to be stable.

    {e %%VERSION%% — {{:%%PKG_HOMEPAGE%% }homepage}} *)

open Bos_setup

(** {1 Odig} *)

(** OCaml compilation objects and their dependencies. *)
module Cobj : sig


  (** {1:cobjs Compilation objects} *)

  (** Compilation object digests. *)
  module Digest : sig
    include module type of Digest
  end

  type mli
  (** The type for [mli] files. *)

  type cmi
  (** The type for [cmi] files. *)

  type cmti
  (** The type for [cmti] files. *)

  type cmo
  (** The type for [cmo] files. *)

  type cma
  (** The type for [cma] files. *)

  type cmx
  (** The type for [cmx] files. *)

  type cmxa
  (** The type for [cmxa] files. *)

  type cmxs
  (** The type for [cmxs] files. *)

  (** [mli] files. *)
  module Mli : sig

    (** {1 Mli} *)

    type t = mli
    (** The type for mli files. *)

    val read : Fpath.t -> (t, R.msg) result
    (** [read f] reads an [mli] file from [f].

        {b Warning.} Does only check the file exists, not that it is
        syntactically correct. *)

    val name : mli -> string
    (** [name mli] is the name of the module interface. *)

    val path : mli -> Fpath.t
    (** [path mli] is the file path to the mli file. *)
  end

  (** [cmi] files. *)
  module Cmi : sig

    (** {1 Cmi} *)

    type t = cmi
    (** The type for cmi files. *)

    val read : Fpath.t -> (t, R.msg) result
    (** [read f] reads a [cmi] file from [f]. *)

    val name : cmi -> string
    (** [name cmi] is the name of the module interface. *)

    val digest : cmi -> Digest.t
    (** [digest cmi] is the digest of the module interface. *)

    val deps : cmi -> (string * Digest.t option) list
    (** [deps cmi] is the list of imported module interfaces names with their
        digest, if known. *)

    val path : cmi -> Fpath.t
    (** [path cmi] is the file path to the [cmi] file. *)

    val compare : cmi -> cmi -> int
    (** [compare cmi cmi'] totally orders [cmi] and [cmi']. *)
  end

  (** [cmti] files. *)
  module Cmti : sig

    (** {1 Cmti} *)

    type t = cmti
    (** The type for [cmti] files. *)

    val read : Fpath.t -> (t, R.msg) result
    (** [read f] reads a [cmti] file from [f]. *)

    val name : cmti -> string
    (** [name cmti] is the name of the module interface. *)

    val digest : cmti -> Digest.t
    (** [digest cmti] is the digest of the module interface. *)

    val deps : cmti -> (string * Digest.t option) list
    (** [deps cmti] is the list of imported module interfaces with their
        digest, if known. *)

    val path : cmti -> Fpath.t
    (** [path cmti] is the file path to the [cmti] file. *)
  end

  (** [cmo] files. *)
  module Cmo : sig

    (** {1 Cmo} *)

    type t = cmo
    (** The type for [cmo] files. *)

    val read : Fpath.t -> (t, R.msg) result
    (** [read f] reads a [cmo] file from [f]. *)

    val name : cmo -> string
    (** [name cmo] is the name of the module implemntation. *)

    val cmi_digest : cmo -> Digest.t
    (** [cmi_digest cmo] is the digest of the module interface of the
        implementation. *)

    val cmi_deps : cmo -> (string * Digest.t option) list
    (** [cmi_deps cmo] is the list of imported module interfaces names
        with their digest, if known. *)

    val cma : cmo -> cma option
    (** [cma cmo] is an enclosing [cma] file (if any). *)

    val path : cmo -> Fpath.t
    (** [path cmo] is the file path to the [cmo] file. Note that this
        is a [cma] file if [cma cmo] is [Some _]. *)
  end

  (** [cma] files. *)
  module Cma : sig

    (** {1 Cma} *)

    type t = cma
    (** The type for cma files. *)

    val read : Fpath.t -> (t, R.msg) result
    (** [read f] reads a [cma] file from [f]. *)

    val name : cma -> string
    (** [name cma] is [cma]'s basename. *)

    val cmos : cma -> cmo list
    (** [cmos cma] are the [cmo]s contained in the [cma]. *)

    val custom : cma -> bool
    (** [custom cma] is [true] if it requires custom mode linking. *)

    val custom_cobjs : cma -> string list
    (** [cma_custom_cobjs] are C objects files needed for custom mode
        linking. *)

    val custom_copts : cma -> string list
    (** [cma_custom_copts] are C link options for custom mode linking. *)

    val dllibs : cma -> string list
    (** [cma_dllibs] are dynamically loaded C libraries for ocamlrun
        dynamic linking. *)

    val path : cma -> Fpath.t
    (** [path cma] is the file path to the [cma] file. *)
  end

  (** [cmx] files. *)
  module Cmx : sig

    (** {1 Cmx} *)

    type t = cmx
    (** The type for [cmx] files. *)

    val read : Fpath.t -> (t, R.msg) result
    (** [read f] reads a [cmx] file from [f]. *)

    val name : cmx -> string
    (** [name cmx] is the name of the module implementation. *)

    val digest : cmx -> Digest.t
    (** [digest cmx] is the digest of the implementation. *)

    val cmi_digest : cmx -> Digest.t
    (** [cmi_digest cmx] is the digest of the module interface of the
        implementation. *)

    val cmi_deps : cmx -> (string * Digest.t option) list
    (** [cmi_deps cmx] is the list of imported module interfaces names
        with their digest, if known. *)

    val cmx_deps : cmx -> (string * Digest.t option) list
    (** [cmx_deps cmx] is the list of imported module implementations names
        with their digest, if known. *)

    val cmxa : cmx -> cmxa option
    (** [cmxa cmx] is an enclosing [cmxa] file (if any). *)

    val path : cmx -> Fpath.t
    (** [path cmx] is the file path to the [cmx] file. Note that this
        is a [cmxa] file if [cmxa cmx] is [Some _]. *)
  end

  (** [cmxa] files. *)
  module Cmxa : sig

    (** {1 Cmxa} *)

    type t = cmxa
    (** The type for [cmxa] files. *)

    val read : Fpath.t -> (t, R.msg) result
    (** [read f] reads a [cmxa] file from [f]. *)

    val name : cmxa -> string
    (** [name cmxa] is [cmxa]'s basename. *)

    val cmxs : cmxa -> cmx list
    (** [cmxs cmxa] are the [cmx]s contained in the [cmxa]. *)

    val cobjs : cmxa -> string list
    (** [cobjs] are C objects needed files needed for linking. *)

    val copts : cmxa -> string list
    (** [copts] are options for the C linker. *)

    val path : cmxa -> Fpath.t
    (** [path cmxa] is the file path to the [cmxa] file. *)
  end

  (** [cmxs] files. *)
  module Cmxs : sig

    (** {1 Cmxs} *)

    type t = cmxs
    (** The type for [cmxs] files. *)

    val read : Fpath.t -> (t, R.msg) result
    (** [read f] reads a [cmxs] file from [f].

        {b Warning.} Only checks that the file exists. *)

    val name : cmxs -> string
    (** [name cmxs] is [cmxs]'s basename. *)

    val path : cmxs -> Fpath.t
    (** [path cmxs] is the file path to the [cmxs] file. *)
  end

  (** {1 Sets of compilation objects.} *)

  type set
  (** The type for sets of compilation objects. *)

  val empty_set : set
  (** [empty_set] is an empty set of compilation objects. *)

  val mlis : set -> mli list
  (** [mlis s] is the list of [mli]s contained in [s]. *)

  val cmis : set -> cmi list
  (** [cmis s] is the list of [cmi]s contained in [s]. *)

  val cmtis : set -> cmti list
  (** [cmtis s] is the list of [cmti]s contained in [s]. *)

  val cmos : ?files:bool -> set -> cmo list
  (** [cmos ~files s] is the list of [cmo]s contained in [s].  If
      [files] is [true] (defaults to [false]), only the [cmo] files
      are listed and [cmo]s that are part of [cma] files are omitted. *)

  val cmas : set -> cma list
  (** [cmas s] is the list of [cma]s contained in [s]. *)

  val cmxs : ?files:bool -> set -> cmx list
  (** [cmxs ~files s] is the list of [cmx]s contained in [s].  If
      [files] is [true] (defaults to [false]), only the [cmx] files
      are listed and [cmx]s that are part of [cmxa] files are omitted. *)

  val cmxas : set -> cmxa list
  (** [cmxa s] is the list of [cmxa]s contained in [s]. *)

  val cmxss : set -> cmxs list
  (** [cmxss s] is the list of [cmxs]s contained in [s]. *)

  val set_of_dir : Fpath.t -> set
  (** [set_of_dir d] is the set of compilation objects that
      are present in the file hierarchy rooted at [d].

      {b Warning.} This is a best-effort function, it will
      log on errors and continue (at worst you'll get an {!empty_set}). *)
end

(** Odig configuration. *)
module Conf : sig

  (** {1 Configuration} *)

  type t
  (** The type for odig configuration. *)

  val default_file : Fpath.t
  (** [default_file] is the default configuration file. *)

  val v :
    ?trust_cache:bool -> cachedir:Fpath.t -> libdir:Fpath.t ->
    docdir:Fpath.t -> unit -> t
  (** [v ~trust_cache ~cachedir ~libdir ~docdir ()] is a configuration
      using [cachedir] as the odig cache directory, [libdir] for
      looking up package compilation objects and [docdir] for looking
      up package documentation. If [trust_cache] is [true] (defaults
      to [false]) indicates the data of [cachedir] should be trusted
      regardless of whether [libdir] and [docdir] may have changed. *)

  val of_file : ?trust_cache:bool -> Fpath.t -> (t, R.msg) result
  (** [of_file f] reads a configuration from configuration file [f].
      See {!v}. *)

  val of_opam_switch :
    ?trust_cache:bool -> ?switch:string -> unit -> (t, R.msg) result
  (** [of_opam_switch ~switch ()] is a configuration for the opam switch
      [switch] (defaults to the current switch). See {!v}. *)

  val libdir : t -> Fpath.t
  (** [libdir c] is [c]'s package library directory. *)

  val docdir : t -> Fpath.t
  (** [docdir c] is [c]'s package documentation directory. *)

  (** {1 Cache} *)

  val cachedir : t -> Fpath.t
  (** [cachedir c] is [c]'s odig cache directory. *)

  val trust_cache : t -> bool
  (** [trust_cache c] indicates if [c] is trusting [odig]'s cache. *)

  val clear_cache : t -> (unit, R.msg) result
  (** [clear_cache c] deletes [c]'s cache directory. *)

  (** {1 Package cache} *)

  val pkg_cachedir : t -> Fpath.t
  (** [pkg_cachedir c] is [c]'s cache directory for packages it is
      located inside {!cachedir}. *)

  val cached_pkgs_names : t -> (String.set, R.msg) result
  (** [cached_pkgs_names c] is the set of names of the packages that
      are cached in [c]. Note that these packages may not correspond
      or be up-to-date with packages {{!Pkg.list}found} in the
      configuration. *)
end

(** Packages.

    Information about how packages are recognized and their data looked up
    is kept in [odig help packaging].

    {b TODO.} Add a note about freshness and concurrent access. *)
module Pkg : sig

  (** {1 Package names} *)

  type name = string
  (** The type for package names. *)

  val is_name : string -> bool
  (** [is_name n] is [true] iff [n] is a valid package name. [n]
      must not be empty and be a valid {{!Fpath.is_segment}path segment}. *)

  val name_of_string : string -> (name, R.msg) result
  (** [name_of_string s] is [Ok s] if [is_name s] is [true] and
      an error message otherwise *)

  val dir_is_package : Fpath.t -> name option
  (** [dir_is_package dir] is [Some name] if a package named [name]
      is detected in directory [dir].

      {b Note} At the moment function will not detect a package name
      if [dir] ends with a relative segment. *)

  (** {1 Packages and lookup} *)

  type t
  (** The type for packages. *)

  type set
  (** The type for package sets. *)

  val set : Conf.t -> (set, R.msg) result
  (** [set c] is the set of all packages in configuration [c]. *)

  val lookup : Conf.t -> name -> (t, R.msg) result
  (** [lookup c n] is the package named [n] in [c]. An error
      is returned if [n] doesn't exist in [c] or if [n] is
      not a {{!is_name}package name}. *)

  val find : Conf.t -> name -> t option
  (** [find c n] tries to find a package named [n] in [c].
      [None] is returned if [n] doesn't exist in [c] or if [n]
      is not a {{!is_name}package name}. *)

  val find_set : Conf.t -> String.set -> set * String.set
  (** [find_set c ns] is [(pkgs, not_found)] where [pkgs] are
      the elements of [ns] which could be matched to a package in
      configuration [c] and [not_found] are those that could not
      be found or are not {{!is_name}package names}. *)

  (** {1 Basic properties} *)

  val field : err:'a -> (t -> ('a, R.msg) result) -> t -> 'a
  (** [field ~err field f] is [v] if [field p = Ok v] and [err] otherwise. *)

  val name : t -> name
  (** [name p] is [p]'s name. *)

  val libdir : t -> Fpath.t
  (** [libdir p] is [p]'s library directory (has the compilation objects). *)

  val docdir : t -> Fpath.t
  (** [docdir p] is [p]'s documentation directory. *)

  val cobjs : t -> Cobj.set
  (** [cobjs p] are [p]'s compilation objects. *)

  (** {1 Package metadata (OPAM file)} *)

  val opam_file : t -> Fpath.t
  (** [opam_file p] is [p]'s expected OPAM file path. *)

  val opam_fields : t -> (string list String.map, R.msg) result
  (** [opam_fields p] is the package's OPAM fields. This is
      {!String.Set.empty} [opam_file p] does not exist. *)

  val license_tags : t -> (string list, R.msg) result
  (** [license_tags p] is [p]'s [license:] field. *)

  val version : t -> (string option, R.msg) result
  (** [version p] is [p]'s [version:] field. *)

  val homepage : t -> (string list, R.msg) result
  (** [version p] is [p]'s [homepage:] field. *)

  val online_doc : t -> (string list, R.msg) result
  (** [online_doc p] is [p]'s [doc:] field. *)

  val issues : t -> (string list, R.msg) result
  (** [issues p] is [p]'s [bug-report:] field. *)

  val tags : t -> (string list, R.msg) result
  (** [tags p] is [p]'s [tags:] field. *)

  val maintainers : t -> (string list, R.msg) result
  (** [maintainers p] is [p]'s [maintainer:] field. *)

  val authors : t -> (string list, R.msg) result
  (** [authors p] is [p]'s [authors:] field. *)

  val repo : t -> (string list, R.msg) result
  (** [repo p] is [p]'s [dev-repo:] field. *)

  val deps : ?opts:bool -> t -> (String.set, R.msg) result
  (** [deps p] are [p]'s OPAM dependencies if [opt] is [true]
      (default) includes optional dependencies. *)

  val depopts : t -> (String.set, R.msg) result
  (** [deps p] are [p]'s OPAM optional dependencies. *)

  (** {1 Standard distribution documentation}

      See {!Odoc} and {!Ocamldoc} for generated documentation. *)

  val readmes : t -> (Fpath.t list, R.msg) result
  (** [readmes p] are the readme files of [p]. *)

  val change_logs : t -> (Fpath.t list, R.msg) result
  (** [change_logs p] are the change log files of [p]. *)

  val licenses : t -> (Fpath.t list, R.msg) result
  (** [licences p] are the license files of [p]. *)

  (** {1 Predicates} *)

  val equal : t -> t -> bool
  (** [equal p p'] is [true] if [p] and [p'] have the same name. *)

  val compare : t -> t -> int
  (** [compare p p'] is a total order on [p] and [p']'s names. *)

  (** {1 Package sets and maps} *)

  (** Package sets. *)
  module Set : Asetmap.Set.S with type elt = t and type t = set

  (** Package maps. *)
  module Map : Asetmap.Map.S_with_key_set with type key = t
                                           and type key_set = Set.t

  (** {1 Classifying} *)

  val classify :
    ?cmp:('a -> 'a -> int) ->
    classes:(t -> 'a list) -> t list -> ('a * Set.t) list

  (** {1 Cache} *)

  val cachedir : t -> Fpath.t
  (** [cachedir p] is [p]'s cache directory, located somewhere in the
      configuration's {!Conf.cachedir}. *)

  type cache_status = [ `New | `Stale | `Fresh ]
  (** The type for package status.
      {ul
        {- [`New] indicates that no cached information could be found
           for the package.}
        {- [`Fresh] indicates that cached information corresponds to the
           package install state. {b Warning.} Freshness only refers to the
           root information handled by this module. For example a
           package may be fresh but it's API documentation may be
           stale.}
        {- [`Stale] indicates that cached information does not
           correspond to the package install's state}} *)

  val cache_status : t -> (cache_status, R.msg) result
  (** [cache_status p] is [p]'s cache status. *)

  val refresh_cache : t -> (unit, R.msg) result
  (** [refresh_cache p] ensures [p]'s cache status becomes
      [`Fresh]. {b Note.} Clients usually don't need to call this
      as it is handled transparently by the API. *)

  val clear_cache : t -> (unit, R.msg) result
  (** [clear_cache p] deletes [p]'s {!cachedir}. Ensures [p]'s
      cache status becomes [`New]. *)
end

(** Compilation objects lookups. *)
module Cobj_index : sig

  (** {1 Compilation objects index} *)

  type t
  (** The type for compilation objects indexes. *)

  val create : Conf.t -> (t, R.msg) result
  (** [create c] is an index for all compilation objects in configuration
      [c]. *)

  type 'a result = (Pkg.t * 'a) list
  (** The type for query results. *)

  val find_digest : t -> Cobj.Digest.t ->
    Cobj.cmi result * Cobj.cmti result * Cobj.cmo result * Cobj.cmx result
  (** [find_digest i d] searches [i] for compilation objects matching
      digest [d]. *)
end

(** [odoc] API documentation generation. *)
module Odoc : sig

  (** {1 Odoc} *)

  val htmldir : Conf.t -> Fpath.t
  (** [htmldir c] is the [odoc] html directory for [c]. *)

  val pkg_htmldir : Pkg.t -> Fpath.t
  (** [pkg_htmldir p] is the [odoc] html directory for package [p]. *)

  val compile : odoc:Cmd.t -> force:bool -> Pkg.t -> (unit, R.msg) result
  (** [compile ~odoc ~force p] compiles the [.odoc] files from the [.cmti]
      files of package [p]. *)

  val html : odoc:Cmd.t -> force:bool -> Pkg.t -> (unit, R.msg) result
  (** [html ~odoc ~force p] generates the html files from the [.odoc]
      files of package [p]. *)

  val htmldir_css_and_index : Conf.t -> (unit, R.msg) result
  (** [htmldir_css_and_index c] generates the [odoc] css and html
      package index for configuration [c]. *)

end

(** [ocamldoc] API documentation generation. *)
module Ocamldoc : sig

  (** {1 Ocamldoc} *)

  val htmldir : Conf.t -> Fpath.t
  (** [htmldir c] is the [ocamldoc] html directory for [c]. *)

  val pkg_htmldir : Pkg.t -> Fpath.t
  (** [pkg_htmldir p] is the [ocamldoc] html directory for package [p]. *)

  val compile : ocamldoc:Cmd.t -> force:bool -> Pkg.t -> (unit, R.msg) result
  (** [compile ~ocamldoc ~force p] compiles the [.ocodoc] files from the [.mli]
      and [.cmi] files of package [p]. *)

  val html : ocamldoc:Cmd.t -> force:bool -> Pkg.t -> (unit, R.msg) result
  (** [html ~ocamldoc ~force] generates the html files from the [.ocodoc] files
      files of package [p]. *)

  val htmldir_css_and_index : Conf.t -> (unit, R.msg) result
  (** [htmldir_css_and_index c] generates the [ocamldoc] css and html
      package index for configuration [c]. *)
end

(** {1 Private} *)

(** Private definitions. *)
module Private : sig

  (** Odig log. *)
  module Log : sig

    (** {1 Log} *)

    val src : Logs.src
    (** [src] is Odig's logging source. *)

    include Logs.LOG

    val on_iter_error_msg :
        ?level:Logs.level -> ?header:string -> ?tags:Logs.Tag.set ->
        (('a -> unit) -> 'b -> 'c) ->
        ('a -> (unit, R.msg) Result.result) -> 'b -> 'c

    val time :
      ?level:Logs.level ->
      ('a ->
       (?tags:Logs.Tag.set -> ('b, Format.formatter, unit, 'a) format4 -> 'b) ->
       'a) ->
      ('c -> 'a) -> 'c -> 'a
  end

(** JSON text generation.

    {b Warning.} The module assumes strings are UTF-8 encoded. *)
  module Json : sig

    (** {1 Generation sequences} *)

    type 'a seq
    (** The type for sequences. *)

    val empty : 'a seq
    (** An empty sequence. *)

    val ( ++ ) : 'a seq -> 'a seq -> 'a seq
    (** [s ++ s'] is sequence [s'] concatenated to [s]. *)

    (** {1 JSON values} *)

    type t
    (** The type for JSON values. *)

    type mem
    (** The type for JSON members. *)

    type el
    (** The type for JSON array elements. *)

    val null : t
    (** [null] is the JSON null value. *)

    val bool : bool -> t
    (** [bool b] is [b] as a JSON boolean value. *)

    val int : int -> t
    (** [int i] is [i] as a JSON number. *)

    val str : string -> t
    (** [str s] is [s] as a JSON string value. *)

    val el : t -> el seq
    (** [el v] is [v] as a JSON array element. *)

    val el_if : bool -> (unit -> t) -> el seq
    (** [el_if c v] is [el (v ())] if [c] is [true] and {!empty} otherwise. *)

    val arr : el seq -> t
    (** [arr els] is an array whose values are defined by the elements [els]. *)

    val mem : string -> t -> mem seq
    (** [mem n v] is an object member whose name is [n] and value is [v]. *)

    val mem_if : bool -> string -> (unit -> t) -> mem seq
    (** [mem_if c n v] is [mem n v] if [c] is [true] and {!empty} otherwise. *)

    val obj : mem seq -> t
    (** [obj mems] is an object whose members are [mems]. *)

    (** {1 Output} *)

    val buffer_add : Buffer.t -> t -> unit
    (** [buffer_add b j] adds the JSON value [j] to [b]. *)

    val to_string : t -> string
    (** [to_string j] is the JSON value [j] as a string. *)

    val output : out_channel -> t -> unit
    (** [output oc j] outputs the JSON value [j] on [oc]. *)
  end

  (** HTML generation. *)
  module Html : sig

    (** {1 Generation sequences} *)

    type 'a seq
    (** The type for sequences. *)

    val empty : 'a seq
    (** An empty sequence. *)

    val ( ++ ) : 'a seq -> 'a seq -> 'a seq
    (** [s ++ s'] is sequence [s'] concatenated to [s]. *)

    (** {1 HTML generation} *)

    type att
    (** The type for attributes. *)

    type attv
    (** The type for attribute values. *)

    type t
    (** The type for elements or character data. *)

    val attv : string -> attv seq
    (** [attv v] is an attribute value [v]. *)

    val att : string -> attv seq -> att seq
    (** [att a v] is an attribute [a] with value [v]. *)

    val data : string -> t seq
    (** [data d] is character data [d]. *)

    val el : string -> ?atts:att seq -> t seq -> t seq
    (** [el e ~atts c] is an element [e] with attribute
        [atts] and content [c]. *)

    (** {1 Derived attributes} *)

    val href : string -> att seq
    (** [href l] is an [href] attribute with value [l]. *)

    val id : string -> att seq
    (** [id i] is an [id] attribute with value [i]. *)

    val class_ : string -> att seq
    (** [class_ c] is a class attribute [c]. *)

    (** {1 Derived elements} *)

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

    (** {1 Output} *)

    val buffer_add : ?doc_type:bool -> Buffer.t -> t seq -> unit
    (** [buffer_add ~doc_type b h] adds the sequence [h] to [b].
        If [doc_type] is [true] (default) an HTML doctype declaration
        is prepended. *)

    val to_string : ?doc_type:bool -> t seq -> string
    (** [to_string] is like {!buffer_add} but returns
        directly a string. *)

    val output : ?doc_type:bool -> out_channel -> t seq -> unit
    (** [output] is like {!buffer_add} but outputs directly on
        a channel. *)
  end

  (** Dot graph generation.

    {b Note.} No support for ports. Should be too hard to add though.

    {b References}
    {ul
    {- {{:http://www.graphviz.org/content/dot-language}Dot language
       grammar}}} *)
  module Dot : sig

    (** {1 Generation sequences} *)

    type 'a seq
    (** The type for sequences. *)

    val empty : 'a seq
    (** An empty sequence. *)

    val ( ++ ) : 'a seq -> 'a seq -> 'a seq
    (** [s ++ s'] is sequence [s'] concatenated to [s]. *)

    (** {1 Graphs} *)

    type id = string
    (** The type for ids, they can be any string and are escaped. *)

    type st
    (** The type for dot statements. *)

    type att
    (** The type for dot attributes. *)

    type t
    (** The type for dot graphs. *)

    val edge : ?atts:att seq -> id -> id -> st seq
    (** [edge ~atts id id'] is an edge from [id] to [id'] with attribute
        [atts] if specified. *)

    val node : ?atts:att seq -> id -> st seq
    (** [nod ~atts id] is a node with id [id] and attributes [atts] if
        specified. *)

    val atts : [`Graph | `Node | `Edge] -> att seq -> st seq
    (** [atts kind atts] are attributes [atts] for [kind]. *)

    val att : string -> string -> att seq
    (** [att k v] is attribute [k] with value [v]. *)

    val label : string -> att seq
    (** [label l] is label attribute [l]. *)

    val color : string -> att seq
    (** [color c] is a color attribute [l]. *)

    val subgraph : ?id:id -> st seq -> st seq
    (** [subgraph ~id sts] is subgraph [id] (default unlabelled) with
        statements [sts]. *)

    val graph :
      ?id:id -> ?strict:bool -> [`Graph | `Digraph] -> st seq -> t
    (** [graph ~id ~strict g sts] is according to [g] a graph or digraph [id]
        (default unlabelled) with statements [sts]. If [strict] is [true]
        (defaults to [false]) multi-edges are not created. *)

    (** {1 Output} *)

    val buffer_add : Buffer.t -> t -> unit
    (** [buffer_add b g] adds the dot graph [g] to [b]. *)

    val to_string : t -> string
    (** [to_string g] is the dot graph [g] as a string. *)

    val output : out_channel -> t -> unit
    (** [output oc g] outputs the dot graph [g] on [oc]. *)
  end

  (** Digests. *)
  module Digest : sig

    (** {1 Digests} *)

    include module type of Digest

    val file : Fpath.t -> (t, R.msg) result
    (** [file f] is the digest of file [f]. *)

    val mtimes : Fpath.t list -> (t, R.msg) result
    (** [mtimes ps] is a digest of the mtimes of [ps]. The [ps] list
        sorted with {!Fpath.compare}. *)
  end

  (** Computation trails.

      {b Do not look at this}. *)
  module Trail : sig
    type t
    val pp_dot : root:Fpath.t -> t Fmt.t
    val pp_dot_universe : root:Fpath.t -> unit Fmt.t
  end

  (** Packages. *)
  module Pkg : sig

    include module type of Pkg
    with type t = Pkg.t
     and type set = Pkg.set
     and module Set = Pkg.Set
     and module Map = Pkg.Map

    val cobjs_trail : t -> Trail.t
    (** [cobjs_trail p] is a trail for {!Cobjs.t}. *)

    val install_trail : t -> Trail.t
    (** [install_trail p] is [p]'s install trail. If the install changes
        the trail's digest updates. *)
  end
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
