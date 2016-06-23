(*---------------------------------------------------------------------------
   Copyright (c) 2016 Daniel C. Bünzli. All rights reserved.
   Distributed under the ISC license, see terms at the end of the file.
   %%NAME%% %%VERSION%%
  ---------------------------------------------------------------------------*)

open Bos_setup

(* Files *)

module File = struct

  (* Try to compose with the OpamFile.OPAM API *)

  let id x = x
  let list f = fun v -> [f v]
  let field name field conv =
    name, fun acc o -> String.Map.add name (conv (field o)) acc

  let opt_field name field conv =
    name, fun acc o -> match field o with
    | None -> acc
    | Some v -> String.Map.add name (conv v) acc

  let deps_conv d =
    let add_pkg acc (n, _) = OpamPackage.Name.to_string n :: acc in
    OpamFormula.fold_left add_pkg [] d

  let fields = [
    opt_field "name" OpamFile.OPAM.name_opt (list OpamPackage.Name.to_string);
    opt_field "version" OpamFile.OPAM.version_opt
      (list OpamPackage.Version.to_string);
    field "opam-version" OpamFile.OPAM.opam_version
      (list OpamVersion.to_string);
    field "available" OpamFile.OPAM.available (list OpamFilter.to_string);
    field "maintainer" OpamFile.OPAM.maintainer id;
    field "homepage" OpamFile.OPAM.homepage id;
    field "authors" OpamFile.OPAM.author id;
    field "license" OpamFile.OPAM.license id;
    field "doc" OpamFile.OPAM.doc id;
    field "tags" OpamFile.OPAM.tags id;
    field "bug-reports" OpamFile.OPAM.bug_reports id;
    opt_field "dev-repo"
      OpamFile.OPAM.dev_repo (list OpamTypesBase.string_of_pin_option);
    field "depends" OpamFile.OPAM.depends deps_conv;
    field "depopts" OpamFile.OPAM.depopts deps_conv;
  ]

  let field_names =
    let add acc (name, field) = String.Set.add name acc in
    List.fold_left add String.Set.empty fields

  let fields file =
    let parse file  =
      let file = OpamFilename.of_string (Fpath.to_string file) in
      let opam = OpamFile.OPAM.read file in
      let known_fields =
        let add_field acc (_, field) = field acc opam in
        List.fold_left add_field String.Map.empty fields
      in
      (* FIXME add OpamFile.OPAM.extensions when supported *)
      known_fields
    in
    Logs.info (fun m -> m "Parsing OPAM file %a" Fpath.pp file);
    try Ok (parse file) with
    | exn ->
        (* Apparently in at least opam-lib 1.2.2, the error will be logged
             on stdout. *)
        R.error_msgf "%a: could not parse OPAM file" Fpath.pp file

  let deps ?(opts = true) fields =
    let deps = match String.Map.find "depends" fields with
    | None -> [] | Some deps -> deps
    in
    let dep_opts =
      if not opts then [] else
      match String.Map.find "depopts" fields with
      | None -> []  | Some deps -> deps
    in
    String.Set.of_list (List.rev_append dep_opts deps)

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
