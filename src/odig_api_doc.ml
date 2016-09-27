(*---------------------------------------------------------------------------
   Copyright (c) 2016 Daniel C. Bünzli. All rights reserved.
   Distributed under the ISC license, see terms at the end of the file.
   %%NAME%% %%VERSION%%
  ---------------------------------------------------------------------------*)

open Bos_setup

module H = Odig_html

(* Access to package fields *)

let get_list f pkg = Odig_pkg.field ~err:[] f pkg
let get_opt_field f pkg = Odig_pkg.field ~err:None f pkg
let get_rel_fpaths htmldir f pkg =
  let ps = get_list f pkg in
  let rel acc p = match Fpath.relativize htmldir p with
  | None ->
      Logs.warn (fun m -> m "%s: Could not relativize %a"
                    (Odig_pkg.name pkg) Fpath.pp p);
      acc
  | Some p -> p :: acc
  in
  List.(rev @@ fold_left rel [] ps)

(* HTML generation *)

let fpath_to_uri p =
  String.concat ~sep:"/" (Fpath.segs p) (* FIXME fpath #1 *)

let type_utf8_text =
  H.(att "type" (attv "text/plain; charset=UTF-8"))

let list e l = H.(List.fold_left (fun acc v -> acc ++ e v) empty l)
let dds def l = H.(dd @@ ul @@ list def l)

let head ~style_href title = (* a basic head *)
  H.(
    el "head" @@
    meta ~atts:(att "charset" (attv "utf-8")) empty ++
    meta ~atts:(att "name" (attv "viewport") ++
                att "content" (attv "width=device-width, initial-scale=1.0"))
      empty ++
    el "link" ~atts:(att "rel" (attv "stylesheet") ++
                     att "type" (attv "text/css") ++
                     att "media" (attv "screen, print") ++
                     href style_href)
      empty ++
    el "title" title)

(* Pkg info fragment *)

let raw_link l = H.(a ~atts:(att "href" (attv l)) (data l))

let rel_file path =
  let l = fpath_to_uri path in
  H.(link ~atts:type_utf8_text l (data @@ Fpath.filename path))

let def_strings fname f def pkg = match get_list f pkg with
| [] -> H.empty
| vs ->
    let vs = List.sort compare vs in
    H.(dt (data fname) ++ dds (fun e -> li @@ def e) vs)

let def_raw_links fname f pkg = match get_list f pkg with
| [] -> H.empty
| links -> H.(dt (data fname) ++ dds raw_link links)

let def_rel_files dir fname f pkg = match get_rel_fpaths dir f pkg with
| [] -> H.empty
| files -> H.(dt (data fname) ++ dds rel_file files)

let def_readmes ~htmldir =
  def_rel_files htmldir "readme" Odig_pkg.readmes

let def_change_logs ~htmldir =
  def_rel_files htmldir "change log" Odig_pkg.change_logs

let def_license_tags =
  def_strings "licenses" Odig_pkg.license_tags H.data

let def_licenses ~htmldir =
  def_rel_files htmldir "licenses" Odig_pkg.licenses

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
      let dst = Fpath.(htmldir dep_pkg / "index.html") in
      let cur = htmldir pkg in
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
  H.(dt (data "version") ++
             dd begin match get_opt_field Odig_pkg.version pkg with
             | None -> data "?"
             | Some v -> data v
             end)

let _pkg_info ~htmldir pkg =
  let pkg_htmldir = htmldir pkg in
  let defs pkg =
    H.(
      empty
      ++ def_authors pkg
      ++ def_change_logs ~htmldir:pkg_htmldir pkg
      ++ def_deps ~htmldir pkg
      ++ def_homepage pkg
      ++ def_issues pkg
      ++ def_license_tags pkg
      ++ def_licenses ~htmldir:pkg_htmldir pkg
      ++ def_maintainers pkg
      ++ def_online_doc pkg
      ++ def_readmes ~htmldir:pkg_htmldir pkg
      ++ def_tags pkg
      ++ def_version pkg)
  in
  H.(dl ~atts:(att "class" (attv "odig-info")) (defs pkg))

let pkg_info ~htmldir pkg =
  H.to_string ~doc_type:false @@ _pkg_info ~htmldir pkg


(* Package title short links *)

let changes_link ~htmldir pkg = match get_list Odig_pkg.change_logs pkg with
| [] -> H.empty
| c :: _ ->
    match Fpath.relativize (htmldir pkg) c with
    | None -> H.empty
    | Some path ->
        H.(link ~atts:type_utf8_text
                     (fpath_to_uri path) (data "changes") ++ data " ")

let issues_link pkg = match get_list Odig_pkg.issues pkg with
| [] -> H.empty
| l :: _ -> H.(link l (data "issues") ++ data " ")

let title_links ~htmldir pkg =
  H.(nav @@ changes_link ~htmldir pkg ++
                    issues_link pkg ++
                    link "#info" (data "info"))

let pkg_title_links ~htmldir pkg =
  H.to_string ~doc_type:false @@ title_links ~htmldir pkg

(* Package module index page *)

let pkg_header ~htmldir pkg =
  let pkgs = H.(a ~atts:(href "../index.html") (data "Packages")) in
  let version = match Odig_pkg.(field ~err:None version pkg) with
  | None -> H.empty
  | Some v -> H.data (v ^ " ")
  in
  H.(h1 (pkgs ++ (data " – ") ++ (data @@ Odig_pkg.name pkg ^ " ") ++
                 version ++ title_links ~htmldir pkg))

let pkg_module_list mods =
  let add_mod acc m =
    H.(acc ++ li (a ~atts:(href (strf "%s/index.html" m)) (data m)))
  in
  H.(ul (List.fold_left add_mod empty mods))

let pkg_page ~htmldir pkg ~mods =
  let title = H.(data @@ Odig_pkg.name pkg) in
  let mods = List.sort String.compare mods in
  H.(html @@
             head ~style_href:"../odoc.css" (* FIXME *) title ++
             (body ~atts:(class_ "odoc-doc") @@
              pkg_header ~htmldir pkg ++
              h2 ~atts:(id "api") (data "API") ++
              pkg_module_list mods ++
              h2 ~atts:(id "info") (data "Info") ++
              (_pkg_info ~htmldir pkg)))

let pkg_page ~htmldir pkg ~mods =
  H.to_string @@ pkg_page ~htmldir pkg ~mods

(* Package index *)

let li_pkg pkg =
  let name = Odig_pkg.name pkg in
  let l = strf "%s/index.html" name in
  H.(li @@ link l (data name))

let name_list pkgs =
  let classes p = [String.get_head @@ Odig_pkg.name p] in
  let classes = Odig_pkg.classify ~classes pkgs in
  let lid c = strf "name-%c" c in
  let letter_link (c, _) =
    H.(link ("#" ^ lid c) (data @@ String.of_char c))
  in
  let letter_sec (c, pkgs) =
    H.(li ~atts:(id @@ lid c) @@
       ol (list li_pkg (Odig_pkg.Set.elements pkgs)))
  in
  H.(div ~atts:(class_ "odig-name") @@
     h1 ~atts:(id "by-name") (data "By name") ++
     nav (list letter_link classes) ++
     ol (list letter_sec classes))

let tag_list pkgs =
  let classes p = (Odig_pkg.tags p) |> R.ignore_error ~use:(fun _ -> []) in
  let classes = Odig_pkg.classify ~classes pkgs in
  let tid t = strf "tag-%s" t in
  let tlink (t, _) = H.(link ("#" ^ tid t) (data t)) in
  let tsec (t, pkgs) =
    H.(li ~atts:(id @@ tid t) @@
       span (data t) ++
       ol (list li_pkg (Odig_pkg.Set.elements pkgs)))
  in
  H.(div ~atts:(class_ "odig-tag") @@
     h1 ~atts:(id "by-tag") (data "By tag") ++
     nav (list tlink classes) ++
     ol (list tsec classes))

let error_list tool pkgs =
  let tool, file_kind = match tool with
  | `Odoc -> "odoc", "cmti"
  | `Ocamldoc -> "ocamldoc", "mli"
  in
  let li_no_doc pkg =
    let name = Odig_pkg.name pkg in
    H.(li @@ data name ++ data " - try " ++
             code (data "odig " ++ data tool ++ data " -f " ++ data name))
  in
  H.(h1 ~atts:(id "errors") (data "Caveat and errors") ++
     el "p" (data " This is a best-effort documentation generation. Toplevel \
                modules may be missing due to errors. The following packages \
                have \
           no API documentation; because it was not generated, because they \
           have no " ++ (code (data file_kind)) ++
          (data " files, or because of errors.")) ++
     ol ~atts:(class_ "odig-errors") (list li_no_doc pkgs))


let online_manual_link =
  H.(link "http://caml.inria.fr/pub/docs/manual-ocaml/"
       (data "OCaml manual") ++ (data " (online, latest version)."))

let manual_link conf ~htmldir =
  let local_man =
    Fpath.(Odig_conf.docdir conf / "ocaml-manual" / "index.html")
  in
  begin
    OS.File.exists local_man >>| function
    | false -> online_manual_link
    | true ->
        match Fpath.relativize ~root:htmldir local_man with
        | None -> online_manual_link
        | Some path ->
            H.(link (fpath_to_uri path) (data "OCaml manual") ++ (data "."))
  end
  |> Odig_log.on_error_msg ~use:(fun _ -> online_manual_link)

let index_page conf ~tool ~htmldir ~has_doc ~no_doc =
  let libdir = Odig_conf.libdir conf in
  let title = H.(data @@ Fpath.(basename @@ parent libdir)) in
  let style_href, cl = match tool with (* FIXME *)
  | `Odoc -> "odoc.css", "odoc-doc"
  | `Ocamldoc -> "style.css", "ocamldoc-doc"
  in
  let comma = H.data ", " in
  H.(html @@
     head ~style_href title ++
     (body ~atts:(class_ cl) @@
      h1 (data "OCaml package documentation") ++
      p (data "For " ++ (data (Fpath.to_string libdir))  ++ data ". See the " ++
         link "#errors" (data "caveat and errors") ++ data ".") ++
      p (data "Browse "
         ++ (link "#by-name" (data "by name")) ++ comma
         ++ (link "#by-tag" (data "by tag")) ++ comma
         ++ (data " the ")
         ++ (link "ocaml/index.html" (data "standard library"))
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
