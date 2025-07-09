(*---------------------------------------------------------------------------
   Copyright (c) 2019 The odig programmers. All rights reserved.
   SPDX-License-Identifier: ISC
  ---------------------------------------------------------------------------*)

open B0_std
open Result.Syntax

let versions () =
  let run = Os.Cmd.run_out ~trim:true in
  let* odig = run Cmd.(tool "odig" % "--version") in
  let* odoc = run Cmd.(tool "odoc" % "--version") in
  Ok (Fmt.str "odig %s and odoc %s" odig odoc)

let odig_html () =
  let cache_path = Cmd.(tool "odig" % "cache" % "path") in
  let* path = Os.Cmd.run_out ~trim:true cache_path in
  let htmldir = Fpath.(v path / "html") in
  let add_element _ f _ acc = f :: acc in
  let* fs = Os.Dir.fold ~recurse:false add_element htmldir [] in
  Ok (htmldir, fs)

let odig_theme_list () =
  let themes = Cmd.(tool "odig" % "odoc-theme" % "list" % "--long") in
  let* themes = Os.Cmd.run_out ~trim:true themes in
  let parse_theme p = match String.cut ~sep:" " (String.trim p) with
  | None -> Fmt.failwith "%S: could not parse theme" p
  | Some (tn, path) -> Fpath.v ("doc@" ^ tn), Fpath.v path
  in
  Ok (List.map parse_theme (String.split ~sep:"\n" (String.trim themes)))

let link_themes dir htmldir_contents themes =
  let theme_link dir htmldir_contents (tdir, tcontents) =
    let dir = Fpath.(dir // tdir) in
    let rec loop = function
    | [] ->
        let dst = Fpath.(dir / "_odoc-theme") in
        Os.Path.copy ~make_path:true
          ~recurse:true tcontents ~dst |> Result.error_to_failure;
        B0_github.Pages.update ~follow_symlinks:false (Some dir) ~dst:tdir
    | f :: fs ->
        if f = "_odoc-theme" then loop fs else
        let src = Fpath.(v ".." / "doc" / f) in
        let dst = Fpath.(dir / f) in
        let force = true and make_path = true in
        Os.Path.symlink ~force ~make_path ~src dst |> Result.error_to_failure;
        loop fs
    in
    let _bool = Os.Dir.create ~make_path:true dir |> Result.error_to_failure in
    loop htmldir_contents
  in
  try Ok (List.map (theme_link dir htmldir_contents) themes) with
  | Failure e -> Error e

let pp_updated ppf = function
| false -> Fmt.string ppf "No update to publish on"
| true -> Fmt.string ppf "Published docs on"

let publish ~color ~new_commit ~remote ~branch =
  let styler = B0_std_cli.get_styler color in
  Fmt.set_styler styler;
  Log.if_error ~use:1 @@
  let* versions = versions () in
  let* htmldir, htmldir_contents = odig_html () in
  Log.stdout (fun m ->
      m "Publishing %a" (Fmt.st' [`Fg `Green] Fpath.pp_quoted) htmldir);
  let* themes = odig_theme_list () in
  Result.join @@
  Os.Dir.with_tmp @@ fun dir ->
  let* theme_updates = link_themes dir htmldir_contents themes in
  let udoc = B0_github.Pages.update (Some htmldir) ~dst:(Fpath.v "doc") in
  let updates = B0_github.Pages.nojekyll :: udoc :: theme_updates in
  let* repo = B0_vcs_repo.get () in
  let msg = Fmt.str "Update sample output with %s." versions in
  let amend = not new_commit and force = true in
  let* updated =
    B0_github.Pages.commit_updates repo ~remote ~branch ~amend ~force ~msg
      updates
  in
  Log.stdout begin fun m ->
      m "[%a] %a %a"
        (Fmt.st [`Fg `Green]) "DONE" pp_updated updated
        B0_vcs_repo.Git.pp_remote_branch
        (remote, B0_github.Pages.default_branch)
  end;
  Ok 0

let main () =
  let open Cmdliner in
  let open Cmdliner.Term.Syntax in
  let cmd =
    let doc = "Updates odig's sample output on GitHub pages" in
    Cmd.make (Cmd.info "publish" ~version:"%%VERSION%%" ~doc) @@
    let+ () = B0_std_cli.set_log_level ()
    and+ new_commit =
      let doc = "Make a new commit, do not amend the last one." in
      Arg.(value & flag & info ["c"; "new-commit"] ~doc)
    and+ remote =
      let doc = "Publish on remote $(docv)." and docv = "REMOTE" in
      Arg.(value & opt string "origin" & info ["remote"] ~doc ~docv)
    and+ branch =
      let doc = "Publish on branch $(docv)." and docv = "BRANCH" in
      let default = B0_github.Pages.default_branch in
      Arg.(value & opt string default & info ["b"; "branch"] ~doc ~docv)
    and+ color = B0_std_cli.color () in
    publish ~color ~new_commit ~remote ~branch
  in
  Cmd.eval' cmd

let () = if !Sys.interactive then exit (main ())
