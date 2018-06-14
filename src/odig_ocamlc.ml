(*---------------------------------------------------------------------------
   Copyright (c) 2016 The odig programmers. All rights reserved.
   Distributed under the ISC license, see terms at the end of the file.
   %%NAME%% %%VERSION%%
  ---------------------------------------------------------------------------*)

open Bos_setup

let failwithf fmt = Fmt.kstrf (fun s -> failwith s) fmt

let failwith_magic_mismatch ~kind ~found ~expected =
  failwithf "not a %s file, found magic %a, expected %a"
    kind String.dump found String.dump expected

let pp_cmt_format_error ppf = function
| Cmt_format.Not_a_typedtree s -> Fmt.pf ppf  "not a typed tree: %s" s

let exn_to_error f v = try f v with
| Sys_error e | Failure e -> R.error_msgf "%s" e
| End_of_file -> R.error_msgf "Unexpected end of file"
| Cmi_format.Error e -> R.error_msgf "%a" Cmi_format.report_error e
| Cmt_format.Error e -> R.error_msgf "%a" pp_cmt_format_error e

let prefix_path_on_error file =
  R.reword_error_msg ~replace:true (fun e -> R.msgf "%a: %s" Fpath.pp file e)

let pp_digest ppf d = Fmt.string ppf (Digest.to_hex d)

let split_dep name deps =
  (* splits digest of [name] from [deps], errors if [name] not in [deps].
     Raises Failure *)
  let rec loop digest acc = function
  | [] ->
      begin match digest with
      | None -> failwithf "self-digest for %s not found" name
      | Some digest -> (digest, List.rev acc)
      end
  | (n, digest') :: deps when n = name ->
      begin match digest with
      | None -> loop digest' acc deps
      | Some d ->
          begin match digest' with
          | None ->
              loop digest acc deps
          | Some d' when d = d' ->
            (* Cf. https://github.com/ocaml/ocaml/pull/744 *)
              loop digest acc deps
          | Some d' ->
              failwithf "multiple self-digest for %s (%a and %a)"
                name pp_digest d pp_digest d'
          end
      end
  | (n, _ as dep) :: deps -> loop digest (dep :: acc) deps
  in
  loop None [] deps

let read_magic ~kind ~magic ic =
  let len = String.length magic in
  let found = really_input_string ic len in
  if not (String.equal found magic)
  then failwith_magic_mismatch ~kind ~found ~expected:magic;
  ()

let seek_data ~kind ~magic ic =
  read_magic ~kind ~magic ic;
  seek_in ic (input_binary_int ic);
  ()

(* Cmi files *)

type cmi =
  { name : string;
    digest : Digest.t;
    deps : (string * Digest.t option) list; }

let read_cmi cmi =
  exn_to_error begin fun () ->
    let info = Cmi_format.read_cmi (Fpath.to_string cmi) in
    let name = info.Cmi_format.cmi_name in
    let digest, deps = split_dep name info.Cmi_format.cmi_crcs in
    Ok { name; digest; deps; }
  end ()
  |> prefix_path_on_error cmi

let cmi_name cmi = cmi.name
let cmi_digest cmi = cmi.digest
let cmi_deps cmi = cmi.deps

(* Cmti files *)
type cmti = cmi

let read_cmti cmti =
  exn_to_error begin fun () ->
    let info = Cmt_format.read_cmi (Fpath.to_string cmti) in
    let name = info.Cmi_format.cmi_name in
    let digest, deps = split_dep name info.Cmi_format.cmi_crcs in
    Ok { name; digest; deps; }
  end ()
  |> prefix_path_on_error cmti

let cmti_name cmti = cmti.name
let cmti_digest cmti = cmti.digest
let cmti_deps cmti = cmti.deps

(* Cmo files. *)

type cmo =
  { name : string;
    cmi_digest : Digest.t;
    cmi_deps : (string * Digest.t option) list; }

let cmo_of_compilation_unit cu =
  let name = cu.Cmo_format.cu_name in
  let cmi_digest, cmi_deps = split_dep name cu.Cmo_format.cu_imports in
  { name; cmi_digest; cmi_deps }

let cmo_of_in_channel ic () =
  seek_data ~kind:"cmo" ~magic:Config.cmo_magic_number ic;
  cmo_of_compilation_unit (input_value ic : Cmo_format.compilation_unit)

let read_cmo cmo =
  exn_to_error (OS.File.with_ic cmo cmo_of_in_channel) ()
  |> prefix_path_on_error cmo

let cmo_name cmo = cmo.name
let cmo_cmi_digest cmo = cmo.cmi_digest
let cmo_cmi_deps cmo = cmo.cmi_deps

(* Cmt files *)

type cmt = cmo

let read_cmt cmt =
  exn_to_error begin fun () ->
    let info = Cmt_format.read_cmt (Fpath.to_string cmt) in
    let name = info.Cmt_format.cmt_modname in
    let cmi_digest, cmi_deps = split_dep name info.Cmt_format.cmt_imports in
    Ok { name; cmi_digest; cmi_deps }
  end ()
  |> prefix_path_on_error cmt

let cmt_name cmt = cmt.name
let cmt_cmi_digest cmt = cmt.cmi_digest
let cmt_cmi_deps cmt = cmt.cmi_deps

(* Cma files *)

type cma =
  { name : string;
    cmos : cmo list;
    custom : bool;
    custom_cobjs : string list;
    custom_copts : string list;
    dllibs : string list; }

let cma_of_library fpath l =
  let name = Fpath.(filename @@ rem_ext fpath) in
  let cmos = List.map cmo_of_compilation_unit l.Cmo_format.lib_units in
  let custom = l.Cmo_format.lib_custom in
  let custom_cobjs = l.Cmo_format.lib_ccobjs in
  let custom_copts = l.Cmo_format.lib_ccopts in
  let dllibs = l.Cmo_format.lib_dllibs in
  { name; cmos; custom; custom_cobjs; custom_copts; dllibs }

let cma_of_in_channel ic fpath =
  seek_data ~kind:"cma" ~magic:Config.cma_magic_number ic;
  cma_of_library fpath (input_value ic : Cmo_format.library)

let read_cma cma =
  exn_to_error (OS.File.with_ic cma cma_of_in_channel) cma
  |> prefix_path_on_error cma

let cma_name cma = cma.name
let cma_cmos cma = cma.cmos
let cma_custom cma = cma.custom
let cma_custom_cobjs cma = cma.custom_cobjs
let cma_custom_copts cma = cma.custom_copts
let cma_dllibs cma = cma.dllibs

(* Cmx files. *)

type cmx =
  { name : string;
    digest : Digest.t;
    cmi_digest : Digest.t;
    cmi_deps : (string * Digest.t option) list;
    cmx_deps : (string * Digest.t option) list; }

let cmx_of_compilation_unit (cu, digest) =
  let name = cu.Cmx_format.ui_name in
  let cmi_digest, cmi_deps = split_dep name cu.Cmx_format.ui_imports_cmi in
  let cmx_deps = cu.Cmx_format.ui_imports_cmx in
  { name; digest; cmi_digest; cmi_deps; cmx_deps }

let cmx_of_in_channel ic () =
  read_magic ~kind:"cmx" ~magic:Config.cmx_magic_number ic;
  let cu = (input_value ic : Cmx_format.unit_infos) in
  let digest = Digest.input ic in
  cmx_of_compilation_unit (cu, digest)

let read_cmx cmx =
  exn_to_error (OS.File.with_ic cmx cmx_of_in_channel) ()
  |> prefix_path_on_error cmx

let cmx_name cmx = cmx.name
let cmx_digest cmx = cmx.digest
let cmx_cmi_digest cmx = cmx.cmi_digest
let cmx_cmi_deps cmx = cmx.cmi_deps
let cmx_cmx_deps cmx = cmx.cmx_deps

(* Cmxa files *)

type cmxa =
  { name : string;
    cmxs : cmx list;
    cobjs : string list;
    copts : string list; }

let cmxa_of_library fpath l =
  let name = Fpath.(filename @@ rem_ext fpath) in
  let cmxs = List.map cmx_of_compilation_unit l.Cmx_format.lib_units in
  let cobjs = l.Cmx_format.lib_ccobjs in
  let copts = l.Cmx_format.lib_ccopts in
  { name; cmxs; cobjs; copts; }

let cmxa_of_in_channel ic fpath =
  read_magic ~kind:"cmxa" ~magic:Config.cmxa_magic_number ic;
  cmxa_of_library fpath (input_value ic : Cmx_format.library_infos)

let read_cmxa cmxa =
  exn_to_error (OS.File.with_ic cmxa cmxa_of_in_channel) cmxa
  |> prefix_path_on_error cmxa

let cmxa_name cmxa = cmxa.name
let cmxa_cmxs cmxa = cmxa.cmxs
let cmxa_cobjs cmxa = cmxa.cobjs
let cmxa_copts cmxa = cmxa.copts

(* Cmxs files *)

type cmxs =
  { name : string; }

let cmxs_of_library fpath () =
  let name = Fpath.(filename @@ rem_ext fpath) in
  { name }

let read_cmxs cmxa = OS.File.must_exist cmxa >>= fun cmxa ->
  Ok (cmxs_of_library cmxa ())

let cmxs_name cmxs = cmxs.name

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
