(*---------------------------------------------------------------------------
   Copyright (c) 2018 The odig programmers. All rights reserved.
   Distributed under the ISC license, see terms at the end of the file.
   %%NAME%% %%VERSION%%
  ---------------------------------------------------------------------------*)

open Odig_support
open B0_std
open B0_htmlg

let anchor_href aid = At.href (Fmt.str "#%s" aid)
let anchor_a aid = El.a ~at:At.[anchor_href aid; class' "anchor"] []
let a_to_utf_8_txt ~href:h txt =
  El.a ~at:At.[type' "text/plain; charset=UTF-8"; href h] [El.txt txt]

let doc_dir_link ?txt f =
  let fname = Fpath.basename (Fpath.v f) in
  let txt = match txt with None -> fname | Some txt -> txt in
  a_to_utf_8_txt ~href:(Fmt.str "_doc-dir/%s" fname) txt

(* Package index.mld file *)

let pkg_title pkg pkg_info =
  let short_info =
    let get_first f el = match Pkg_info.get f pkg_info with
    | [] -> El.txt "" | v :: _ -> el v
    in
    let version = get_first `Version @@ fun version ->
      El.span ~at:At.[class' "version"] [El.txt version]
    in
    let changes_link = get_first `Changes_files @@ fun c ->
      doc_dir_link ~txt:"changes" c
    in
    let issues_link = get_first `Issues @@ fun issues ->
      El.a ~at:At.[href issues] [El.txt "issues"]
    in
    let info_link = El.a ~at:At.[href "#package_info"] [El.txt "more…"] in
    let sp = El.txt " " in
    [version; sp; El.nav [changes_link; sp; issues_link; sp; info_link]]
  in
  Fmt.str "{0:package-%s Package %s {%%html:%s%%}}"
    (Pkg.name pkg) (Pkg.name pkg)
    (El.to_string ~doc_type:false (El.splice short_info))

let ocaml_pkg_module_indexes pkg_info =
  (* Too much noise to use regular index generation. We cook up
     something manually. People should simply stop vomiting in the
     ocaml directory. The day upstream wants control over it can
     provide an `index.mld` file at the right place. It will override
     this. *)
  let cobjs = Pkg_info.doc_cobjs pkg_info in
  let dirid f = Fpath.basename (Fpath.parent f) in
  let add_cobj acc cobj =
    if Doc_cobj.don't_list cobj then acc else
    let dirid = dirid (Doc_cobj.path cobj) in
    match String.Map.find dirid acc with
    | exception Not_found -> String.Map.add dirid [cobj] acc
    | cobjs -> String.Map.add dirid (cobj :: cobjs) acc
  in
  let bydir = List.fold_left add_cobj String.Map.empty cobjs in
  let dirmods dirid libid lib = match String.Map.find dirid bydir with
  | exception Not_found -> ""
  | cobjs ->
      let mods = List.rev_map Doc_cobj.modname cobjs in
      let mods = List.sort String.compare mods in
      Fmt.str "{1:%s %s}\n{!modules: %s}\n" libid lib (String.concat " " mods)
  in
  Fmt.str "%s%s%s"
    (dirmods "ocaml" "stdlib" "Stdlib")
    (dirmods "threads" "threads" "Threads")
    (dirmods "compiler-libs" "compiler_libs" "Compiler libs")

let pkg_index pkg pkg_info ~user_index =
  let drop_section_0 s = match String.cut_left ~sep:"{0" s with
  | Some (t, r) when String.trim t = "" ->
      (* can break but should be mostly ok *)
      let max = String.length r in
      let rec loop c i max = match i > max with
      | true -> s
      | false ->
          match r.[i] with
          | '{' -> loop (c + 1) (i + 1) max
          | '}' when c = 1 -> String.drop_left (i + 1) r
          | '}' -> loop (c - 1) (i + 1) max
          | _ -> loop c (i + 1) max
      in
      loop 1 0 max
  | _ -> s
  in
  match user_index with
  | Some user_index -> drop_section_0 user_index
  | None when Pkg.name pkg = "ocaml" -> ocaml_pkg_module_indexes pkg_info
  | None ->
      let cobjs = Pkg_info.doc_cobjs pkg_info in
      let cobjs = List.filter (fun c -> not (Doc_cobj.don't_list c)) cobjs in
      let mods = List.rev_map Doc_cobj.modname cobjs in
      let mods = List.sort String.compare mods in
      Fmt.str "{!modules: %s}" (String.concat " " mods)

let pkg_info_section pkg pkg_info ~with_tag_links =
  let def_values field fname fval i  =match Pkg_info.get field i with
  | [] -> El.txt ""
  | vs ->
      let fid = Fmt.str "info-%s" fname in
      let vs = List.sort compare vs in
      let vs = List.map (fun v -> El.li (fval v)) vs in
      El.tr ~at:At.[id fid] El.[td [(anchor_a fid); txt fname]; td [ul vs]]
  in
  let defs pkg pkg_info =
    let string_val str = [El.txt str] in
    let uri_val uri = [El.a ~at:At.[href uri] [El.txt uri]] in
    let file_val f = [doc_dir_link f] in
    let pkg_val pkg =
      [El.a ~at:At.[href (Fmt.str "../%s/index.html" pkg)] [El.txt pkg]]
    in
    let tag_val t = match with_tag_links with
    | true -> [El.a ~at:At.[href (Fmt.str "../index.html#tag-%s" t)] [El.txt t]]
    | false -> [El.txt t]
    in
    [ def_values `Authors "authors" string_val pkg_info;
      def_values `Changes_files "changes-files" file_val pkg_info;
      def_values `Depends "depends" pkg_val pkg_info;
      def_values `Homepage "homepage" uri_val pkg_info;
      def_values `Issues "issues" uri_val pkg_info;
      def_values `License "license" string_val pkg_info;
      def_values `License_files "license-files" file_val pkg_info;
      def_values `Maintainers "maintainers" string_val pkg_info;
      def_values `Online_doc "online-doc" uri_val pkg_info;
      def_values `Readme_files "readme-files" file_val pkg_info;
      def_values `Repo "repo" string_val pkg_info;
      def_values `Tags "tags" tag_val pkg_info;
      def_values `Version "version" string_val pkg_info ]
  in
  Fmt.str "{1:package_info Package info}\n {%%html:%s%%}" @@
  El.to_string ~doc_type:false
    (El.table ~at:At.[class' "package"; class' "info"] (defs pkg pkg_info))

let index_mld conf pkg pkg_info ~user_index ~with_tag_links =
  Fmt.str "%s\n%s\n%s"
    (pkg_title pkg pkg_info)
    (pkg_index pkg pkg_info ~user_index)
    (pkg_info_section pkg pkg_info ~with_tag_links)

(* Package list *)

let pkg_li conf ~pid pkg =
    let info = try Pkg.Map.find pkg (Conf.pkg_infos conf) with
    | Not_found -> assert false (* formally, could be racy *)
    in
    let name = Pkg.name pkg in
    let version = String.concat " " (Pkg_info.get `Version info) in
    let synopsis = String.concat " " (Pkg_info.get `Synopsis info) in
    let index = Fmt.str "%s/index.html" name in
    let pid = pid name in
    El.li ~at:At.[id pid] [
        anchor_a pid;
        El.a ~at:At.[href index] [El.txt name]; El.txt " ";
        El.span ~at:At.[class' "version"] [El.txt version]; El.txt " ";
        El.span ~at:At.[class' "synopsis"] [El.txt synopsis]; ]

let pkg_list conf pkgs =
  let letter_id l = Fmt.str "name-%s" l in
  let letter_link (l, _) = El.(a ~at:At.[anchor_href (letter_id l)] [txt l]) in
  let letter_section (l, pkgs) =
    let pkgs = List.sort Pkg.compare_by_caseless_name pkgs in
    let letter_id = letter_id l in
    let pid = Fmt.str "package-%s" in
    El.splice @@
    [El.h3 ~at:At.[id letter_id] [anchor_a letter_id; El.txt l];
     El.ol ~at:At.[class' "packages"] (List.map (pkg_li conf ~pid) pkgs)]
  in
  let by_name = "by-name" in
  let classes p = [String.of_char (Char.Ascii.lowercase (Pkg.name p).[0])] in
  let classes = List.classify ~cmp_elts:Pkg.compare ~classes pkgs in
  El.div ~at:At.[class' by_name] [
      El.h2 ~at:At.[id by_name] [anchor_a by_name; El.txt "Packages by name"];
      El.nav (List.map letter_link classes);
      El.splice (List.map letter_section classes) ]

let tag_list conf pkgs =
  let tag_id t = Fmt.str "tag-%s" t in
  let tag_links tags =
    let tag_li (t, _) = El.(li [a ~at:At.[anchor_href (tag_id t)] [txt t]]) in
    let tags_by_letter (letter, tags) =
      let lid = Fmt.str "tags-%s" letter in
      El.(tr ~at:At.[id lid]
            [td [anchor_a lid; txt letter];
             td [ol ~at:At.[class' "tags"] (List.map tag_li tags)]])
    in
    let classes (t, _) = [String.of_char (Char.Ascii.lowercase t.[0])] in
    let cmp_elts (t, _) (t', _) = String.compare t t' in
    let tag_classes = List.classify ~cmp_elts ~classes tags in
    El.table (List.map tags_by_letter tag_classes)
  in
  let tag_section (t, pkgs) =
    let pkgs = List.sort Pkg.compare_by_caseless_name pkgs in
    let tag_id = tag_id t in
    let pid = Fmt.str "tag-%s-package-%s" t in
    El.splice @@
    [El.h3 ~at:At.[id tag_id] [anchor_a tag_id; El.span [El.txt t]];
     El.ol ~at:At.[class' "packages"] (List.map (pkg_li conf ~pid) pkgs)]
  in
  let by_tag = "by-tag" in
  let pkg_infos = Conf.pkg_infos conf in
  let classes p = try Pkg_info.get `Tags (Pkg.Map.find p pkg_infos) with
  | Not_found -> assert false
  in
  let classes = List.classify ~cmp_elts:Pkg.compare ~classes pkgs in
  El.div ~at:At.[class' by_tag] [
    El.h2 ~at:At.[id by_tag] [anchor_a by_tag; El.txt "Packages by tag"];
    El.nav [tag_links classes];
    El.splice (List.map tag_section classes)]

let manual_reference conf ~ocaml_manual_uri =
  let manual_online = "https://caml.inria.fr/pub/docs/manual-ocaml/" in
  let uri, suff = match ocaml_manual_uri with
  | None -> manual_online, El.txt " (online, latest version)."
  | Some href -> href, El.txt ""
  in
  El.splice @@ [El.a ~at:At.[href uri] [El.txt "OCaml manual"]; suff], uri

let stdlib_link conf =
  let htmldir = Conf.html_dir conf in
  let new_style_stdlib = "ocaml/Stdlib/index.html" in
  let old_style_stdlib = "ocaml/index.html#stdlib" in
  let stdlib = Fpath.(htmldir // v new_style_stdlib) in
  match Os.File.exists stdlib |> Log.if_error ~use:false with
  | false -> old_style_stdlib
  | true -> new_style_stdlib ^ "#modules"

let pkgs_with_html_docs conf =
  let by_names = Pkg.by_names (Conf.pkgs conf) in
  let add_pkg _ name dir acc =
    let exists = Os.File.exists Fpath.(dir / "index.html") in
    match exists |> Log.if_error ~level:Log.Warning ~use:false with
    | false -> acc
    | true ->
        match String.Map.find name by_names with
        | exception Not_found -> acc
        | pkg -> pkg :: acc
  in
  let pkgs = Os.Dir.fold_dirs ~recurse:false add_pkg (Conf.html_dir conf) [] in
  let pkgs = pkgs |> Log.if_error ~level:Log.Warning ~use:[] in
  List.sort Pkg.compare pkgs

let pkg_list
    conf ~index_title ~raw_index_intro ~tag_index ~ocaml_manual_uri pkgs =
  (* XXX for now it's easier to do it this way. In the future we should
     rather use the ocamldoc language. Either by using
     https://github.com/ocaml/odoc/issues/94 or `--fragment`. So
     that we don't have to guess the way package links are formed. *)
  let doc_head ~style_href page_title = (* a basic head *)
    El.head [
      El.meta ~at:At.[charset "utf-8"];
      El.meta ~at:At.[name "generator"; content "odig %%VERSION%%"];
      El.meta ~at:At.[name "viewport";
                   content "width=device-width, initial-scale=1.0"];
      El.link ~at:At.[rel "stylesheet"; type' "text/css"; media "screen, print";
                      href style_href; ];
      El.title [El.txt page_title]]
  in
  let doc_header =
    let comma = El.txt ", " in
    let manual_markup, manual_href = manual_reference conf ~ocaml_manual_uri in
    let contents = match raw_index_intro with
    | Some h -> [El.raw h]
    | None ->
        let stdlib_link = stdlib_link conf in
        let browse_by_tag = match tag_index with
        | true -> El.(splice [a ~at:At.[href "#by-tag"] [txt "by tag"]; comma])
        | false -> El.splice []
        in
        let packages_by_tag_li = match tag_index with
        | false -> El.splice []
        | true ->
            El.li [El.a ~at:At.[href "#by-tag"] [El.txt "Packages by tag"]]
        in
        [ El.h1 [El.txt "OCaml package documentation"];
          El.p [El.txt "Browse ";
                El.a ~at:At.[href "#by-name"] [El.txt "by name"]; comma;
                browse_by_tag;
                El.txt " the ";
                El.a ~at:At.[href stdlib_link] [El.txt "standard library"];
                El.txt " and the "; manual_markup; El.txt ".";];
          El.p [El.small [El.txt "Generated for ";
                          El.code
                            [El.txt (Fpath.to_string (Conf.lib_dir conf))]]];
          El.nav ~at:At.[class' "toc"] [
            El.ul [
              El.li [El.a ~at:At.[href stdlib_link]
                       [El.txt "OCaml standard library"]];
              El.li [El.a ~at:At.[href manual_href] [El.txt "OCaml manual"]];
              El.li [El.a ~at:At.[href "#by-name"] [El.txt "Packages by name"]];
              packages_by_tag_li; ]]]
    in
    El.header El.[ nav [txt "\xF0\x9F\x90\xAB"]; splice contents ]
  in
  let style_href = "_odoc-theme/odoc.css" in
  let page_title = match index_title with
  | None -> Fpath.(basename @@ parent (Conf.lib_dir conf))
  | Some t -> t
  in
  El.to_string ~doc_type:true @@
  El.html [
    doc_head ~style_href page_title;
    El.body ~at:At.[class' "odig";
                    (* see https://github.com/ocaml/odoc/issues/298 *)
                    class' "content"]
      [ doc_header;
        pkg_list conf pkgs;
        if tag_index then tag_list conf pkgs else El.splice []]]

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
