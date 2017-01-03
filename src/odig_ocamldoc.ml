(*---------------------------------------------------------------------------
   Copyright (c) 2016 Daniel C. Bünzli. All rights reserved.
   Distributed under the ISC license, see terms at the end of the file.
   %%NAME%% %%VERSION%%
  ---------------------------------------------------------------------------*)

open Bos_setup

(* Finding the -I for a mli file. *)

let mli_cmi_deps idx pkg mli =
  let add_cmi acc (name, d) = match d with
  | None -> acc
  | Some d ->
      match Odig_cobj.Index.cmis_for_interface idx (`Digest d) with
      | [] ->
          Odig_log.debug
            (fun m -> m "%s: %a: No cmi found for %s (%s)"
                (Odig_pkg.name pkg) Fpath.pp mli name (Digest.to_hex d));
          acc
      | (_, cmi) :: cmis ->
          (* Any should do (though could introduce clashes through -I) *)
          cmi :: acc
  in
  let cmi = Fpath.(mli -+ ".cmi") in
  OS.File.exists cmi >>= function
  | false -> Ok []
  | true ->
      Odig_cobj.Cmi.read cmi >>= fun cmi ->
      let deps = Odig_cobj.Cmi.deps cmi in
      Ok (List.fold_left add_cmi [] deps)

let mli_incs idx pkg mli =
  let add_inc acc cmi = Fpath.(Set.add (parent (Odig_cobj.Cmi.path cmi)) acc) in
  begin
    let init = Fpath.Set.singleton (Fpath.parent mli) in
    mli_cmi_deps idx pkg mli >>| fun cmis ->
    Fpath.Set.elements @@ List.fold_left add_inc init cmis
  end
  |> Odig_log.on_error_msg ~use:(fun _ -> [])

(* ocamldoc generation *)

let htmldir conf = Fpath.(Odig_conf.cachedir conf / "ocamldoc")
let pkg_htmldir pkg =
  let htmldir = htmldir (Odig_pkg.conf pkg) in
  Fpath.(htmldir / Odig_pkg.name pkg)

let css_file conf = Fpath.(Odig_etc.dir / "ocamldoc.css")

let compile_dst pkg mli =
  let pkgdir = Odig_pkg.libdir pkg in
  let cachedir = Odig_pkg.cachedir pkg in
  match Fpath.rem_prefix pkgdir mli with
  | None -> assert false
  | Some p -> Fpath.(cachedir // p -+ ".ocodoc")

let compile_mli ~ocamldoc ~force idx pkg mli =
  let mli = Odig_cobj.Mli.path mli in
  let dst = compile_dst pkg mli in
  let cobjs_trail = Odig_pkg.cobjs_trail pkg in
  let dst_trail = Odig_btrail.v ~id:(Fpath.to_string dst) in
  let no_warn = Cmd.(v "-hide-warnings" % "-w" % "-a") in
  let incs = Cmd.(of_values ~slip:"-I" p @@ mli_incs idx pkg mli) in
  let odoc = Cmd.(ocamldoc %% no_warn % "-dump" % p dst %% incs % p mli) in
  let is_fresh =
    if force then Ok false else match Odig_btrail.status dst_trail with
    | `Stale -> Ok false
    | `Fresh ->
        (* FIXME this is ugly *)
        if Odig_btrail.witness dst_trail = Some "ERROR" then Ok true else
        OS.File.exists dst
  in
  is_fresh >>= function
  | true -> Ok ()
  | false ->
      OS.Dir.create ~path:true (Fpath.parent dst) >>= fun _ ->
      OS.Cmd.run_status odoc >>= begin function
      | `Exited 0 -> Odig_digest.file dst >>| fun d -> Some d
      | _ ->
          OS.File.delete dst (* ocamldoc leaves leftovers *)
          >>| fun () -> Some "ERROR" (* FIXME *)
      end >>| fun digest ->
      Odig_btrail.set_witness ~preds:([cobjs_trail]) dst_trail digest

let compile ~ocamldoc ~force pkg =
  let mlis = Odig_cobj.mlis (Odig_pkg.cobjs pkg) in
  Odig_pkg.conf_cobj_index (Odig_pkg.conf pkg) >>= fun idx ->
  let compile_mli = compile_mli ~ocamldoc ~force idx pkg in
  Odig_log.time
    (fun _ m -> m "Compiled ocamldoc odoc files of %s" (Odig_pkg.name pkg))
    (Odig_log.on_iter_error_msg List.iter compile_mli) mlis;
  Ok ()

let pkg_odocs pkg =
  let add_odoc (seen, odocs as acc) mli =
    let odoc = compile_dst pkg mli in
    begin OS.File.exists odoc >>| function
    | false -> acc
    | true ->
        let fname = Fpath.filename odoc in
        match String.Set.mem fname seen with
        | false -> (String.Set.add fname seen, odoc :: odocs)
        | true ->
            Odig_log.info
              (fun m -> m ~header:"HEURISTIC"
                  "%s: Multiple %s file, skipping %a"
                  (Odig_pkg.name pkg) fname Fpath.pp odoc);
            acc
    end
    |> Logs.on_error_msg ~use:(fun _ -> acc)
  in
  let mlis = Odig_cobj.mlis (Odig_pkg.cobjs pkg) in
  let mlis = List.rev_map Odig_cobj.Mli.path mlis in
  let mlis =
    (* part of the dupe heuristics, take smallest path on dupe *)
    List.sort Fpath.compare mlis
  in
  snd @@ List.fold_left add_odoc (String.Set.empty, []) mlis

let make_version p =
  match Odig_pkg.version p |> R.ignore_error ~use:(fun _ -> None) with
  | None -> ""
  | Some v -> " " ^ v

let html_index_page pkg ocdocs =
  let mod_of_ocdoc ocdoc =
    String.Ascii.capitalize Fpath.(filename @@ rem_ext ocdoc)
  in
  let mods = List.map mod_of_ocdoc ocdocs in
  let mod_list = String.concat ~sep:" " @@  List.sort String.compare mods in
  strf "{%%html:\
         <nav><a href=\"../index.html\">Up</a></nav>%%}\n\
        {1 Package %s%s {%%html:%s%%}}\n\
        {!modules: %s}\n\
        {!indexlist}\n\
        {%%html:%s%%}"
    (Odig_pkg.name pkg) (make_version pkg)
    (Odig_api_doc.pkg_title_links ~htmldir:pkg_htmldir pkg)
    mod_list
    (Odig_api_doc.pkg_info ~htmldir:pkg_htmldir pkg)

let html ~ocamldoc ~force pkg =
  let htmldir = pkg_htmldir pkg in
  let pkg_to_html pkg =
    let mlis = Odig_cobj.mlis (Odig_pkg.cobjs pkg) in
    match mlis with
    | [] ->
        Odig_log.info (fun m -> m "%s: No mli files found" (Odig_pkg.name pkg));
        OS.Dir.delete ~recurse:true htmldir
    | _ ->
        match pkg_odocs pkg with
        | [] ->
            Odig_log.info
              (fun m -> m "%s: No odoc files generated" (Odig_pkg.name pkg));
            OS.Dir.delete ~recurse:true htmldir
        | ocdocs ->
            let html_trail = Odig_btrail.v ~id:(Fpath.to_string htmldir) in
            let ocdoc_trails =
              List.map (fun o -> Odig_btrail.v ~id:(Fpath.to_string o)) ocdocs
            in
            let is_fresh =
              if force then Ok false else
              match Odig_btrail.status html_trail with
              | `Fresh -> OS.Dir.exists htmldir
              | `Stale -> Ok false
            in
            is_fresh >>= function
            | true -> Ok ()
            | false ->
                OS.File.tmp "odig-ocpage-%s" >>= fun intro_file ->
                let loads = Cmd.(of_values ~slip:"-load" p ocdocs) in
                let css = Cmd.(v "-css-style" % "../style.css") in
                let html = Cmd.(v "-html" % "-charset" % "utf-8") in
                let intro = Cmd.(v "-intro" % p intro_file) in
  (*            let title = Cmd.(v "-t" % Odig_pkg.name pkg) in *)
                let odoc = Cmd.(ocamldoc % "-hide-warnings" %% loads %
                                "-sort" %% html %% css % "-colorize-code" %%
                                intro % "-short-functors" % "-d" % p htmldir)
            in
            OS.File.write intro_file (html_index_page pkg ocdocs)
            >>= fun () -> OS.Cmd.run_status odoc
            >>= begin function
            | `Exited 0 ->
                (* We don't really care about the digest *)
                Odig_digest.mtimes [htmldir] >>| fun d -> Some d
            | _ ->
                OS.Dir.delete ~recurse:true htmldir >>| fun () -> None
            end >>| fun digest ->
            Odig_btrail.set_witness ~preds:ocdoc_trails html_trail digest
  in
  OS.Dir.create ~path:true htmldir >>= fun _ ->
  Odig_log.time
    (fun _ m -> m "Compiled HTML files of %s" (Odig_pkg.name pkg))
    pkg_to_html pkg

let rec htmldir_css_and_index conf =
  let partition pkgs =
    let classify p (has_doc, no_doc as acc) =
      begin
        OS.Dir.exists (pkg_htmldir p) >>| function
        | true -> (p :: has_doc, no_doc)
        | false -> (has_doc, p :: no_doc)
      end
      |> Odig_log.on_error_msg ~use:(fun _ -> acc)
    in
    let has_doc, no_doc = Odig_pkg.Set.fold classify pkgs ([], []) in
    List.rev has_doc, List.rev no_doc
  in
  let htmldir = htmldir conf in
  Odig_pkg.set conf
  >>= function pkgs -> Ok (partition pkgs)
  >>= fun (has_doc, no_doc) ->
  Ok (Odig_api_doc.pkg_index conf ~tool:`Ocamldoc ~htmldir ~has_doc ~no_doc)
  >>= fun index -> OS.File.write Fpath.(htmldir / "index.html") index
  >>= fun () -> OS.File.read (css_file conf)
  >>= fun css -> OS.File.write Fpath.(htmldir / "style.css") css

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
