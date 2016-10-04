(*---------------------------------------------------------------------------
   Copyright (c) 2016 Daniel C. Bünzli. All rights reserved.
   Distributed under the ISC license, see terms at the end of the file.
   %%NAME%% %%VERSION%%
  ---------------------------------------------------------------------------*)

open Bos_setup

(* odoc generation *)

let htmldir conf = Fpath.(Odig_conf.cachedir conf / "odoc")
let css_file conf = Fpath.(Odig_etc.dir / "odoc.css")

let pkg_htmldir pkg =
  let htmldir = htmldir (Odig_pkg.conf pkg) in
  Fpath.(htmldir / Odig_pkg.name pkg)

let compile_dst pkg cmti =
  let pkgdir = Odig_pkg.libdir pkg in
  let cachedir = Odig_pkg.cachedir pkg in
  match Fpath.rem_prefix pkgdir cmti with
  | None -> assert false
  | Some p -> Fpath.(cachedir // p -+ ".odoc")

let cmti_deps pkg cmti =
  let cmti_path = Odig_cobj.Cmti.path cmti in
  let add_cmti i acc (name, d) = match d with
  | None -> acc
  | Some d ->
      match Odig_cobj.Index.find_cmti i d with
      | [] ->
          Logs.warn
            (fun m -> m "%s: %a: No cmti found for %s (%s)"
                (Odig_pkg.name pkg) Fpath.pp cmti_path name (Digest.to_hex d));
          acc
      | cmti :: cmtis ->
          (* Any should do FIXME really ? *)
          cmti :: acc
  in
  Odig_pkg.conf_cobj_index (Odig_pkg.conf pkg)
  >>= fun i ->
  let deps = Odig_cobj.Cmti.deps cmti in
  Ok (List.fold_left (add_cmti i) [] deps)

let incs_of_deps ?(odoc = false) deps =
  let add acc (pkg, cmti) =
    let path = Odig_cobj.Cmti.path cmti in
    let path = if odoc then compile_dst pkg path else path in
    Fpath.(Set.add (parent path) acc)
  in
  let incs = Fpath.Set.elements @@ List.fold_left add Fpath.Set.empty deps in
  Cmd.(of_values ~slip:"-I" p incs)

let rec build_cmti_deps ~odoc seen pkg cmti = (* FIXME not t.r. *)
  let build seen (pkg, cmti) =
    Logs.on_error_msg ~use:(fun _ -> seen) (_compile_cmti ~odoc seen pkg cmti)
  in
  (cmti_deps pkg cmti >>| fun deps ->
   deps, List.fold_left build seen deps)
  |> Logs.on_error_msg ~use:(fun _ -> [], seen)

and _compile_cmti ~odoc seen pkg cmti =
  let cmti_path = Odig_cobj.Cmti.path cmti in
  if Fpath.Set.mem cmti_path seen then (Ok seen) else
  let seen = Fpath.Set.add cmti_path seen in
  let dst = compile_dst pkg cmti_path in
  OS.File.exists dst >>= function
  | true ->
      (* FIXME hash dance *) Ok seen
  | false ->
      let deps, seen = build_cmti_deps ~odoc seen pkg cmti in
      let incs = incs_of_deps deps in
      let pkg = Cmd.(v "--pkg" % Odig_pkg.name pkg) in
      let odoc = Cmd.(odoc % "compile" %% incs %% pkg % "-o" % p dst %
                      p cmti_path)
      in
      OS.Dir.create ~path:true (Fpath.parent dst) >>= fun _ ->
      OS.Cmd.run odoc >>= fun _ ->
      Ok seen

and compile_cmti ~odoc pkg cmti =
  _compile_cmti ~odoc Fpath.Set.empty pkg cmti >>| fun _ -> ()

let compile ~odoc ~force pkg =
  let cmtis = Odig_cobj.cmtis (Odig_pkg.cobjs pkg) in
  let compile_cmti = compile_cmti ~odoc pkg in
  Odig_log.time
    (fun _ m -> m "Compiled odoc files of %s" @@ Odig_pkg.name pkg)
    (Odig_log.on_iter_error_msg List.iter compile_cmti) cmtis;
  Ok ()

let html_of_odoc ~odoc pkg cmti =
  let cmti_path = Odig_cobj.Cmti.path cmti in
  let odoc_file = compile_dst pkg cmti_path in
  cmti_deps pkg cmti >>= fun deps ->
  let incs = incs_of_deps ~odoc:true deps in
  let htmldir = htmldir (Odig_pkg.conf pkg) in
  OS.Cmd.run Cmd.(odoc % "html" %% incs % "-o" % p htmldir % p odoc_file)

let html_index pkg htmldir cmtis =
  let mods = List.map Odig_cobj.Cmti.name cmtis in
  let page = Odig_api_doc.pkg_page ~htmldir:pkg_htmldir pkg ~mods in
  OS.File.write Fpath.(htmldir / "index.html") page

let html ~odoc ~force pkg =
  let htmldir = pkg_htmldir pkg in
  let cmtis = Odig_cobj.cmtis (Odig_pkg.cobjs pkg) in
  let html pkg =
    let html_of_odoc = html_of_odoc ~odoc pkg in
    Odig_log.on_iter_error_msg List.iter html_of_odoc cmtis;
    html_index pkg htmldir cmtis
  in
  OS.Dir.create ~path:true htmldir >>= fun _ ->
  Odig_log.time
    (fun _ m -> m "Compiled HTML files of %s" @@ Odig_pkg.name pkg)
    html pkg

let htmldir_css_and_index conf =
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
  Ok (Odig_api_doc.pkg_index ~tool:`Odoc ~htmldir conf ~has_doc ~no_doc)
  >>= fun index -> OS.File.write Fpath.(htmldir / "index.html") index
  >>= fun () -> OS.File.read (css_file conf)
  >>= fun css -> OS.File.write Fpath.(htmldir / "odoc.css") css

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
