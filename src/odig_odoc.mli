(*---------------------------------------------------------------------------
   Copyright (c) 2018 The odig programmers. All rights reserved.
   SPDX-License-Identifier: ISC
  ---------------------------------------------------------------------------*)

(** [odoc] API reference generation.

    This mainly implements an [odoc] file resolution and generation
    request procedure specific to [odig]. Generic [odoc] driving bits
    are provided via {!B0_odoc}. *)

open Odig_support

val gen :
  Conf.t -> force:bool -> index_title:string option ->
  index_intro:B0_std.Fpath.t option -> index_toc:B0_std.Fpath.t option ->
  pkg_deps:bool -> tag_index:bool ->
  Pkg.t list -> (unit, string) result
(** [gen c ~force ~index_intro ~pkg_deps ~tag_index pkgs]
    generates API reference for packages [pkgs].
    {ul
    {- [index_title] is the title of the page
       with the list of packages.}
    {- [index_intro] if specified is an mld file to
       define the introduction of the page with the list of packages.}
    {- [index_toc] if specified is an mld file to
       define the table of contents for the page with the list of packages.}
    {- [pkg_deps] if [true] dependencies of [pkgs] are also generated.
       If [false] only [pkgs] are generated which may lead to broken
       links in the output.}
    {- [tag_index] if [true] a tag index is generated on the package list
       page and package pages hyperlink into it from the package information
       section.}} *)

val install_theme : Conf.t -> B0_odoc.Theme.t option -> (unit, string) result
