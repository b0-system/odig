(*---------------------------------------------------------------------------
   Copyright (c) 2016 Daniel C. Bünzli. All rights reserved.
   Distributed under the ISC license, see terms at the end of the file.
   %%NAME%% %%VERSION%%
  ---------------------------------------------------------------------------*)

open Bos_setup

(* Package names *)

type name = string
let is_name s =
  let is_name_char = function
  | '0' .. '9' | 'a' .. 'z' | 'A' .. 'Z' | '-' | '_' -> true
  | _ -> false
  in
  s <> "" && String.for_all is_name_char s

let name_of_string s = match is_name s with
| true -> Ok s
| false -> R.error_msgf "%S: not a package name" s

let pkg_libdir conf name = Fpath.(Odig_conf.libdir conf / name)
let pkg_docdir conf name = Fpath.(Odig_conf.docdir conf / name)
let pkg_cachedir conf name = Fpath.(Odig_conf.pkg_cachedir conf / name)
let pkg_opam_file conf name = Fpath.(pkg_libdir conf name / "opam")

(* Package detection *)

let is_package dir =
  begin
    match Fpath.basename dir with
    | "" (* FIXME relative segment or root path, can't name. Maybe
            we should use realpath(3) somewhere, sometimes *) -> Ok false
    | name when not (is_name name) -> Ok false
    | name ->
        OS.Path.exists Fpath.(dir / "opam") >>= function
        | true -> Ok true
        | false ->
            OS.Path.exists Fpath.(dir / "META") >>= function
            | true -> Ok true
            | false ->
                (* FIXME special case the compiler *)
                OS.Path.exists Fpath.(dir / "caml")
  end
  |> Odig_log.on_error_msg ~use:(fun _ -> false)

let dir_is_package dir = match is_package dir with
| false -> None
| true -> (Some (Fpath.basename dir)) (* can't be empty *)

(* Packages *)

type cache = Odig_cobj.set

type t =
  { name : name;
    conf : Odig_conf.t;
    opam_fields : (string list String.map, R.msg) result Lazy.t;
    install_trail : Odig_btrail.t Lazy.t;
    cache : (Odig_btrail.t * cache) Lazy.t (* Cached package info. *) }

let field ~err f p = match f p with Ok v -> v | Error _ -> err
let name p = p.name
let conf p = p.conf

(* Sets and Maps *)

module Pkg = struct
  type pkg = t
  type t = pkg
  let compare = compare
end

module Set = Asetmap.Set.Make (Pkg)
type set = Set.t

let classify
    (type c) ?(cmp : c -> c -> int = Pervasives.compare) ~classes pkgs =
  let module M = Map.Make (struct type t = c let compare = cmp end) in
  let add_classes acc p =
    let add_class acc c =
      try M.add c (Set.add p (M.find c acc)) acc
      with Not_found -> M.add c (Set.singleton p) acc
    in
    List.fold_left add_class acc (classes p)
  in
  M.bindings (List.fold_left add_classes M.empty pkgs)

module Map = Asetmap.Map.Make_with_key_set (Pkg) (Set)

(* Package directories and files. *)

let libdir p = pkg_libdir p.conf p.name
let docdir p = pkg_docdir p.conf p.name
let cachedir p = pkg_cachedir p.conf p.name
let cache_file p = Fpath.(cachedir p / "pkg.cache")

(* Digest and cache.

   The install digest is made of the mtimes of all the paths (files
   and directories) of a packages' libdir and docdir. *)

let install_digest p =
  let digest p =
    let paths = [libdir p] in
    let docdir = docdir p in
    let paths = OS.Path.exists docdir >>| function
    | true -> docdir :: paths
    | false -> paths
    in
    paths
    >>= fun paths -> OS.Path.fold (fun p ps -> p :: ps) [] paths
    >>= fun ps -> Odig_digest.mtimes ps
  in
  Odig_log.time (fun _ m -> m "Digest %s" p.name) digest p


let install_trail p = Lazy.force p.install_trail

let _raw_install_trail p = Odig_btrail.v ~id:p.name

let _install_trail p = (* automatically updates the install trail *)
  let t = _raw_install_trail p in
  let digest = ((install_digest p >>| fun d -> Some d)
                |> Odig_log.on_error_msg ~use:(fun _ -> None))
  in
  Odig_btrail.set_witness t digest;
  t

type cache_status = [ `Fresh | `New | `Stale ]

let cache_status p = match Odig_btrail.witness (_raw_install_trail p) with
| None -> Ok `New
| Some d -> install_digest p >>| fun d' -> if (d = d') then `Fresh else `Stale

let refresh_cache p = Ok (ignore (Lazy.force p.cache))

let clear_cache p =
  let d = cachedir p in
  Odig_log.info (fun m -> m "Deleting %a" Fpath.pp d);
  Odig_btrail.delete ~succs:`Delete (_raw_install_trail p);
  OS.Dir.delete ~recurse:true d

let with_cachedir p f v =
  OS.Dir.create ~path:true (cachedir p) >>= fun _ -> f v

let memo ~file ~preds read write =
  let header = "CACHE" in
  let memo f p =
    let preds = preds p in
    let file = file p in
    let t = Odig_btrail.v ~id:(Fpath.to_string file) in
    let cache f p =
      let v = f p in
      begin
        Odig_log.debug (fun m -> m ~header "[WRITE] %a" Fpath.pp file);
        with_cachedir p (write file) v
        >>= fun () -> Odig_digest.file file
        >>| fun d -> Odig_btrail.set_witness ~preds t (Some d); (t, v)
      end
      |> Odig_log.on_error_msg
        ~use:(fun _ -> Odig_btrail.set_witness t None; (t, v))
    in
    match Odig_btrail.status t with
    | `Stale ->
        Odig_log.debug (fun m -> m ~header "[STALE] %a" Fpath.pp file);
        cache f p
    | `Fresh ->
        Odig_log.debug (fun m -> m ~header "[FRESH] %a" Fpath.pp file);
        (read file >>| fun v -> (t, v))
        |> Odig_log.on_error_msg ~use:(fun _ -> cache f p)
  in
  memo

let memo_cache =
  let file = cache_file in
  let preds p = [install_trail p] in (* This will update the trail on access *)
  let cache_codec = Odig_codec.v () in
  let read = Odig_codec.read cache_codec in
  let write = Odig_codec.write cache_codec in
  memo ~file ~preds read write (fun p -> Odig_cobj.set_of_dir (libdir p))

let _cache p =
  Odig_log.time (fun _ m -> m "Cache %s" p.name) memo_cache p

let cobjs_trail p = fst (Lazy.force p.cache)
let cobjs p = snd (Lazy.force p.cache)

(* OPAM file and fields *)

let pkg_opam_fields conf name =
  let opam_file = pkg_opam_file conf name in
  OS.File.exists opam_file >>= function
  | false -> Ok String.Map.empty
  | true -> Odig_opam.File.fields opam_file

(* Package lookup *)

let memo = (* FIXME switch to ephemerons (>= 4.03) *) Hashtbl.create 343

let v name conf = try Hashtbl.find memo (name, conf) with
| Not_found ->
    let opam_fields = lazy (pkg_opam_fields conf name) in
    let rec cache = lazy (_cache pkg)
    and install_trail = lazy (_install_trail pkg)
    and pkg = { name; conf; opam_fields; install_trail; cache } in
    Hashtbl.add memo (name, conf) pkg;
    pkg

let set conf =
  OS.Dir.contents (Odig_conf.libdir conf) >>| fun candidates ->
  let rec add_pkg acc dir = match is_package dir with
  | false -> acc
  | true -> Set.add (v (Fpath.filename dir) conf) acc
  in
  List.fold_left add_pkg Set.empty candidates

let find conf name = match name_of_string name with
| Error _ -> None
| Ok name ->
    match is_package (pkg_libdir conf name) with
    | true -> Some (v name conf)
    | false -> None

let find_set conf names =
  let add_name name (pkgs, not_found) = match name_of_string name with
  | Error _ -> pkgs, String.Set.add name not_found
  | Ok name ->
      match find conf name with
      | None -> pkgs, String.Set.add name not_found
      | (Some pkg) -> (Set.add pkg pkgs), not_found
  in
  String.Set.fold add_name names (Set.empty, String.Set.empty)

let lookup conf name =
  name_of_string name >>= fun name ->
  match is_package (pkg_libdir conf name) with
  | true -> Ok (v name conf)
  | false -> R.error_msgf "%s: No such package." name

(* Index compilation objects of configurations. *)

let memo : (Odig_conf.t, (t Odig_cobj.index, R.msg) Result.result) Hashtbl.t =
  (* FIXME switch to ephemerons (>= 4.03) *) Hashtbl.create 143

let conf_cobj_index c = try Hashtbl.find memo c with
| Not_found ->
    let i =
      let index pkgs =
        let add p acc = Odig_cobj.Index.of_set ~init:acc p (cobjs p) in
        Set.fold add pkgs Odig_cobj.Index.empty
      in
      set c >>| fun pkgs ->
      Odig_log.time (fun _ m -> m "Created index.") index pkgs
    in
    Hashtbl.add memo c i;
    i

(* OPAM *)

let opam_file p = pkg_opam_file p.conf p.name
let opam_fields p = Lazy.force p.opam_fields

let opam_field_value p f =
  opam_fields p >>= function fields ->
  match String.Map.find f fields with
  | None -> Ok None
  | Some vs -> Ok (Some (String.concat ~sep:"" vs))

let opam_field_values p f =
  opam_fields p >>= function fields ->
  match String.Map.find f fields with
  | None -> Ok []
  | Some vs -> Ok vs

let license_tags p = opam_field_values p "license"
let version p = opam_field_value p "version"
let homepage p = opam_field_values p "homepage"
let online_doc p = opam_field_values p "doc"
let issues p = opam_field_values p "bug-reports"
let tags p = opam_field_values p "tags"
let authors p = opam_field_values p "authors"
let maintainers p = opam_field_values p "maintainer"
let repo p = opam_field_values p "dev-repo"
let deps ?opts p =
  opam_fields p >>| fun fields ->
  Odig_opam.File.deps ?opts fields

let depopts p = opam_field_values p "depopts" >>| String.Set.of_list

(* Standard distribution documentation *)

let doc_files p ~sat =
  OS.Dir.contents (docdir p)
  >>= fun files -> Ok (List.filter sat files)

let match_caseless_prefixes prefixes p =
  let filename = String.Ascii.uppercase (Fpath.filename p) in
  let prefix affix = String.is_infix ~affix filename in
  List.exists prefix prefixes

let readmes p =
  let sat = match_caseless_prefixes ["README"] in
  doc_files p ~sat

let change_logs p =
  let sat = match_caseless_prefixes ["CHANGE"; "HISTORY"] in
  doc_files p ~sat

let licenses p =
  let sat = match_caseless_prefixes ["LICENSE"] in
  doc_files p ~sat

(* Predicates *)

let equal p0 p1 = String.equal p0.name p1.name
let compare p0 p1 = String.compare p0.name p1.name

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
