(*---------------------------------------------------------------------------
   Copyright (c) 2016 Daniel C. Bünzli. All rights reserved.
   Distributed under the ISC license, see terms at the end of the file.
   %%NAME%% %%VERSION%%
  ---------------------------------------------------------------------------*)

open Bos_setup

module H = Odig_html

let fpath_to_uri p =
  String.concat ~sep:"/" (Fpath.segs p) (* FIXME fpath #1 *)

let href_is_rel href = (* Someone will hate me for this at some point. *)
  not (String.exists (Char.equal ':') href)

let href_ensure_dir href = match String.head ~rev:true href with
    | None -> href | Some '/' -> href | Some _ -> href ^ "/"

(* Access to package fields *)

let get_list f pkg = Odig_pkg.field ~err:[] f pkg
let get_opt_field f pkg = Odig_pkg.field ~err:None f pkg
let version_data pkg = match get_opt_field Odig_pkg.version pkg with
| None -> H.data "?"
| Some v -> H.data v

(* HTML generation *)

let type_utf_8_text =
  H.(att "type" (attv "text/plain; charset=UTF-8"))

let anchored_cl = "anchored"
let anchor_id ?(classes = []) aid =
  let classes = String.concat ~sep:" " (anchored_cl :: classes) in
  H.(id aid ++ class_ classes)

let anchor ?(text = H.empty) aid =
  H.(a ~atts:(href (strf "#%s" aid) ++ class_ "anchor") text)

let head ~style_href title = (* a basic head *)
  H.(el "head" @@
     meta ~atts:(att "charset" (attv "utf-8")) empty ++
     meta ~atts:(att "name" (attv "generator") ++
                 att "content" (attv "odig %%VERSION%%")) empty ++
     meta ~atts:(att "name" (attv "viewport") ++
                 att "content" (attv "width=device-width, initial-scale=1.0"))
       empty ++
     el "link" ~atts:(att "rel" (attv "stylesheet") ++
                      att "type" (attv "text/css") ++
                      att "media" (attv "screen, print") ++
                      href style_href)
       empty ++
     el "title" title)

let docdir_link ?(atts = H.empty) ?text conf ~cur_dir ~cur_href_path file =
  let text = match text with
  | None -> H.data @@ Fpath.filename file
  | Some t -> t
  in
  let link l = Some H.(link ~atts l text) in
  let link = match Odig_conf.docdir_href conf with
  | None ->
      begin match Fpath.relativize ~root:cur_dir file with
      | None -> None
      | Some rel_file -> link (fpath_to_uri rel_file)
      end
  | Some href ->
      let href = href_ensure_dir href in
      match Fpath.rem_prefix (Odig_conf.docdir conf) file with
      | None -> assert false
      | Some file ->
          let fhref = href ^ fpath_to_uri file in
          match href_is_rel fhref with
          | false -> link fhref
          | true ->
              match Fpath.of_string fhref with
              | Error _ -> None
              | Ok fhref ->
                  match Fpath.relativize ~root:cur_href_path fhref with
                  | None -> None
                  | Some href -> link (fpath_to_uri href)
  in
  match link with
  | Some link -> link
  | None ->
      Odig_log.warn (fun m -> m "Could not linkify %a" Fpath.pp file);
      H.(span ~atts:(class_ ".xref-unresolved") text)

(* Package page header, title and quick links *)

let changes_link ~htmldir pkg = match get_list Odig_pkg.change_logs pkg with
| [] -> H.empty
| c :: _ ->
    let atts = type_utf_8_text in
    let text = H.data "changes" in
    let conf = Odig_pkg.conf pkg in
    let cur_dir = htmldir (Some pkg) in
    let cur_href_path = Fpath.v (Odig_pkg.name pkg) in
    H.(docdir_link ~atts ~text conf ~cur_dir ~cur_href_path c ++ data " ")

let issues_link pkg = match get_list Odig_pkg.issues pkg with
| [] -> H.empty
| l :: _ -> H.(link l (data "issues") ++ data " ")

let pkg_page_header ~htmldir pkg =
  let nav_up = H.(nav @@ a ~atts:(href "../index.html") (data "Up")) in
  let version = match Odig_pkg.(field ~err:None version pkg) with
  | None -> H.empty
  | Some v -> H.(span ~atts:(class_ "version") (data v) ++ data " ")
  in
  let h = H.(h1 ~atts:(class_ "package") @@
             (data "Package ") ++ (data @@ Odig_pkg.name pkg ^ " ") ++
             version ++
             (nav @@ changes_link ~htmldir pkg ++
                     issues_link pkg ++
                     link "#info" (data "info")))
  in
  H.to_string ~doc_type:false @@ H.(nav_up ++ h)

(* Pkg info fragment *)

let raw_link l = H.(a ~atts:(att "href" (attv l)) (data l))

let tr_anchor ?nid name value =
  let nid = match nid with None -> name | Some nid -> nid in
  let nid = strf "info-%s" nid in
  H.(tr ~atts:(anchor_id nid) @@
     td (anchor nid ++ data name) ++
     td value)

let values def l = H.(ul @@ list def l)

let def_strings ?nid fname f def pkg = match get_list f pkg with
| [] -> H.empty
| vs ->
    let vs = List.sort compare vs in
    H.(tr_anchor ?nid fname @@ values (fun e -> li @@ def e) vs)

let def_raw_links ?nid fname f pkg = match get_list f pkg with
| [] -> H.empty
| links -> H.(tr_anchor ?nid fname @@ values raw_link links)

let def_docdir_links ?nid htmldir fname f pkg =
  let link_path path =
    let atts = type_utf_8_text in
    let conf = Odig_pkg.conf pkg in
    let cur_dir = htmldir (Some pkg) in
    let cur_href_path = Fpath.v (Odig_pkg.name pkg) in
    H.(docdir_link ~atts conf ~cur_dir ~cur_href_path path)
  in
  match get_list f pkg with
  | [] -> H.empty
  | files -> H.(tr_anchor ?nid fname @@ values link_path files)

let def_readmes ~htmldir =
  def_docdir_links htmldir "readme" Odig_pkg.readmes

let def_change_logs ~htmldir =
  def_docdir_links htmldir ~nid:"changelog" "change log" Odig_pkg.change_logs

let def_license_tags =
  def_strings "licenses" ~nid:"license-tags" Odig_pkg.license_tags H.data

let def_licenses ~htmldir =
  def_docdir_links htmldir "licenses" Odig_pkg.licenses

let def_issues =
  def_raw_links "issues" Odig_pkg.issues

let def_homepage =
  def_raw_links "homepage" Odig_pkg.homepage

let def_tags pkg =
  let linkify tag =
    H.(link (strf "../index.html#tag-%s" tag) (data tag))
  in
  def_strings "tags" Odig_pkg.tags linkify pkg

let def_deps ~htmldir pkg =
  let conf = Odig_pkg.conf pkg in
  let linkify dep = match Odig_pkg.find conf dep with
  | None -> H.data dep
  | Some dep_pkg ->
      let dst = Fpath.(htmldir (Some dep_pkg) / "index.html") in
      let cur = htmldir (Some pkg) in
      begin match Fpath.relativize ~root:cur dst with
      | None -> H.data dep
      | Some d -> H.(link (fpath_to_uri d) (data dep))
      end
  in
  let deps pkg =
    Odig_pkg.deps ~opts:false pkg >>| fun d -> String.Set.elements d
  in
  let depopts pkg =
    Odig_pkg.depopts pkg >>| fun d -> String.Set.elements d
  in
  H.(def_strings "deps" deps linkify pkg ++
     def_strings "depopts" depopts linkify pkg)

let def_authors =
  def_strings "authors" Odig_pkg.authors H.data

let def_maintainers =
  def_strings "maintainers" Odig_pkg.maintainers H.data

let def_online_doc =
  def_raw_links "online-doc" Odig_pkg.online_doc

let def_version pkg =
  H.(tr_anchor "version" @@ version_data pkg)

let pkg_page_info ~htmldir pkg =
  let defs pkg =
    H.(empty
       ++ def_authors pkg
       ++ def_change_logs ~htmldir pkg
       ++ def_deps ~htmldir pkg
       ++ def_homepage pkg
       ++ def_issues pkg
       ++ def_license_tags pkg
       ++ def_licenses ~htmldir pkg
       ++ def_maintainers pkg
       ++ def_online_doc pkg
       ++ def_readmes ~htmldir pkg
       ++ def_tags pkg
       ++ def_version pkg)
  in
  let iid = "info" in
  H.to_string ~doc_type:false @@
  H.(h2 ~atts:(anchor_id iid) (anchor iid ++ data "Info") ++
     table ~atts:(class_ "package info") (defs pkg))

(* Package module index page *)

let group_cmis_by_archive pkg cmis =
  let cobjs = Odig_pkg.cobjs pkg in
  let find_archive cmi =
    let find obj_cmi_digest obj_path ext objs =
      let dig = Odig_cobj.Cmi.digest cmi in
      let find o = dig = obj_cmi_digest o && Fpath.has_ext ext (obj_path o) in
      try Some (obj_path @@ List.find find objs) with Not_found -> None
    in
    match Odig_cobj.(find Cmo.cmi_digest Cmo.path ".cma" (cmos cobjs)) with
    | Some _ as v -> v
    | None -> Odig_cobj.(find Cmx.cmi_digest Cmx.path ".cmxa" (cmxs cobjs))
  in
  let add_cmi acc cmi =
    let k, k_segs = match find_archive cmi with
    | None -> "", []
    | Some p ->
        match Fpath.rem_prefix (Odig_pkg.libdir pkg) p with
        | None -> assert false
        | Some p -> let p = Fpath.rem_ext p in Fpath.to_string p, Fpath.segs p
    in
    let cmis = match String.Map.find k acc with
    | None -> [cmi]
    | Some (_, cmis) -> cmi :: cmis
    in
    String.Map.add k (k_segs, cmis) acc
  in
  let cmp (a, (ss, _)) (a', (ss', _)) = (* order archives by subdir level *)
    let c = compare (List.length ss) (List.length ss') in
    if c <> 0 then c else compare a a'
  in
  List.sort cmp @@
  String.Map.bindings @@ List.fold_left add_cmi String.Map.empty cmis

let pkg_module_lists tool pkg =
  let group_header tool group =
    (* We do this ourselves because in {2:id bla} [id] can't have dashes
       and a lot of archives do have them. *)
    let hx = match tool with `Ocamldoc -> H.h2 | `Odoc -> H.h3 in
    let sel = strf "sel-%s" group in
    H.(to_string ~doc_type:false @@
       hx ~atts:(anchor_id ~classes:["sel"] sel) (anchor sel ++ data group))
  in
  let mods cmis =
    let mod_of_cmi cmi =
      let cmi = Odig_cobj.Cmi.path cmi in
      String.Ascii.capitalize Fpath.(filename @@ rem_ext cmi)
    in
    let mods = List.map mod_of_cmi cmis in
    let mod_list = String.concat ~sep:" " @@ List.sort String.compare mods in
    strf "{!modules: %s}" mod_list
  in
  let cmis = Odig_cobj.cmis (Odig_pkg.cobjs pkg) in
  let groups = group_cmis_by_archive pkg cmis in
  let add_group acc (group, (_, cmis)) = match cmis with
  | [] -> assert false
  | [cmi] as cmis -> mods cmis :: acc
  | cmis ->
      let by_name c c' = Odig_cobj.(compare (Cmi.name c) (Cmi.name c')) in
      let cmis = List.sort by_name cmis in
      let mods = mods cmis in
      match group with
      | "" -> mods :: acc
      | group ->
          let h = strf "{%%html:%s%%}" (group_header tool group) in
          mods :: h :: acc
  in
  String.concat ~sep:"" @@ List.rev (List.fold_left add_group [] groups)

let pkg_page_mld ~tool ~htmldir pkg =
  let indexes = match tool with `Odoc -> "" | `Ocamldoc -> "{!indexlist}" in
  strf "{%%html:%s%%}%s%s{%%html:%s%%}"
    (pkg_page_header ~htmldir pkg)
    (pkg_module_lists tool pkg)
    indexes
    (pkg_page_info ~htmldir pkg)

(* Package index *)

let name_list pkgs =
  let li_pkg pkg =
    let name = Odig_pkg.name pkg in
    let l = strf "%s/index.html" name in
    let pid = strf "package-%s" name in
    H.(li ~atts:(anchor_id pid) @@
       anchor pid ++ link l (data name) ++
       data " " ++
       span ~atts:(class_ "version") (version_data pkg))
  in
  let classes p = [Char.Ascii.lowercase @@ String.get_head @@ Odig_pkg.name p]in
  let classes = Odig_pkg.classify ~classes pkgs in
  let lid c = strf "name-%c" c in
  let letter_link (c, _) = H.(link ("#" ^ lid c) @@ data (String.of_char c)) in
  let letter_sec (c, pkgs) =
    let cmp p p' =
      let n p = String.Ascii.lowercase (Odig_pkg.name p) in
      String.compare (n p) (n p')
    in
    let pkgs = List.sort cmp (Odig_pkg.Set.elements pkgs) in
    H.(li ~atts:(id @@ lid c) @@ ol (list li_pkg pkgs))
  in
  let byname = "by-name" in
  H.(div ~atts:(class_ byname) @@
     h2 ~atts:(anchor_id byname) (anchor byname ++ data "By name") ++
     nav (list letter_link classes) ++
     ol (list letter_sec classes))

let tag_list pkgs =
  let li_pkg pkg =
    let name = Odig_pkg.name pkg in
    let l = strf "%s/index.html" name in
    H.(li @@ link l (data name))
  in
  let classes p = (Odig_pkg.tags p) |> R.ignore_error ~use:(fun _ -> []) in
  let classes = Odig_pkg.classify ~classes pkgs in
  let tid t = strf "tag-%s" t in
  let tlink (t, _) = H.(link ("#" ^ tid t) (data t)) in
  let tsec (t, pkgs) =
    let tid = tid t in
    H.(li ~atts:(anchor_id tid) @@
       anchor tid ++
       span (data t) ++
       ol (list li_pkg (Odig_pkg.Set.elements pkgs)))
  in
  let bytag = "by-tag" in
  H.(div ~atts:(class_ bytag) @@
     h2 ~atts:(anchor_id bytag) (anchor bytag ++ data "By tag") ++
     nav (list tlink classes) ++
     ol (list tsec classes))

let error_list tool pkgs =
  let tool, file_kind = match tool with
  | `Odoc -> "odoc", "cmi"
  | `Ocamldoc -> "ocamldoc", "mli"
  in
  let li_no_doc pkg =
    let name = Odig_pkg.name pkg in
    H.(li @@ data name ++ data " - try " ++
             code (data "odig " ++ data tool ++ data " -f " ++ data name))
  in
  let errid = "errors" in
  H.(div ~atts:(class_ "errors") @@
     h2 ~atts:(anchor_id errid) (anchor errid ++ data "Caveat and errors") ++
     el "p" (data " This is a best-effort documentation generation. Toplevel \
                modules may be missing due to errors. The following packages \
                have \
           no API documentation; because it was not generated, because they \
           have no " ++ (code (data file_kind)) ++
          (data " files, or because of errors.")) ++
     ol (list li_no_doc pkgs))

let online_manual_link =
  H.(link "http://caml.inria.fr/pub/docs/manual-ocaml/"
       (data "OCaml manual") ++ (data " (online, latest version)."))

let manual_link conf ~htmldir =
  let htmlroot = htmldir None in
  let local = Fpath.(Odig_conf.docdir conf / "ocaml-manual" / "index.html") in
  begin
    OS.File.exists local >>| function
    | false -> online_manual_link
    | true ->
        let text = H.data "OCaml manual" in
        let cur_dir = htmlroot in
        let cur_href_path = Fpath.v "." in
        H.(docdir_link ~text conf ~cur_dir ~cur_href_path local ++ data ".")
  end
  |> Odig_log.on_error_msg ~use:(fun _ -> online_manual_link)

let index_page conf ~tool ~htmldir ~has_doc ~no_doc =
  let libdir = Odig_conf.libdir conf in
  let title = H.(data @@ Fpath.(basename @@ parent libdir)) in
  let style_href = match tool with (* FIXME *)
  | `Odoc -> "odoc.css"
  | `Ocamldoc -> "style.css"
  in
  let comma = H.data ", " in
  H.(html @@
     head ~style_href title ++
     (body ~atts:(class_ "odig") @@
      nav ~atts:(id "top") (data "\xF0\x9F\x90\xAB") ++
      h1 (data "OCaml package documentation") ++
      p (data "For " ++ (data (Fpath.to_string libdir)) ++ data ". See the " ++
         link "#errors" (data "caveat and errors") ++ data ".") ++
      p (data "Browse "
         ++ (link "#by-name" (data "by name")) ++ comma
         ++ (link "#by-tag" (data "by tag")) ++ comma
         ++ (data " the ")
         ++ (link "ocaml/index.html#sel-stdlib" (data "standard library"))
         ++ data " and the " ++ (manual_link conf ~htmldir))
      ++ name_list has_doc
      ++ tag_list has_doc
      ++ error_list tool no_doc))

let pkg_index conf ~tool ~htmldir ~has_doc ~no_doc =
  H.to_string @@ index_page conf ~tool ~htmldir ~has_doc ~no_doc

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
