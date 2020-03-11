(*---------------------------------------------------------------------------
   Copyright (c) 2018 The odig programmers. All rights reserved.
   Distributed under the ISC license, see terms at the end of the file.
  ---------------------------------------------------------------------------*)

(** [odoc] API reference generation.

    This mainly implements an [odoc] file resolution and generation
    request procedure specific to [odig]. Generic [odoc] driving bits
    are provided via {!B0_odoc}. *)

open Odig_support

val gen :
  Conf.t -> force:bool -> index_title:string option ->
  index_intro:B00_std.Fpath.t option -> pkg_deps:bool -> tag_index:bool ->
  Pkg.t list -> (unit, string) result
(** [gen c ~force ~index_intro ~pkg_deps ~tag_index pkgs]
    generates API reference for packages [pkgs].
    {ul
    {- [index_title] is the title of the page
       with the list of packages.}
    {- [index_intro] if specified is an mld file to
       define the introduction of the page with the list of packages.}
    {- [pkg_deps] if [true] dependencies of [pkgs] are also generated.
       If [false] only [pkgs] are generated which may lead to broken
       links in the output.}
    {- [tag_index] if [true] a tag index is generated on the package list
       page and package pages hyperlink into it from the package information
       section.}} *)

val install_theme : Conf.t -> B00_odoc.Theme.t option -> (unit, string) result

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
