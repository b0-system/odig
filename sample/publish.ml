(*---------------------------------------------------------------------------
   Copyright (c) 2019 The odig programmers. All rights reserved.
   SPDX-License-Identifier: ISC
  ---------------------------------------------------------------------------*)

open B0_std
open Result.Syntax

let versions () =
  let run = Os.Cmd.run_out ~trim:true in
  let* odig = run Cmd.(atom "odig" % "--version") in
  let* odoc = run Cmd.(atom "odoc" % "--version") in
  Ok (Fmt.str "odig %s and odoc %s" odig odoc)

let odig_html () =
  let cache_path = Cmd.(atom "odig" % "cache" % "path") in
  let* path = Os.Cmd.run_out ~trim:true cache_path in
  let htmldir = Fpath.(v path / "html") in
  let add_element _ f _ acc = f :: acc in
  let* fs = Os.Dir.fold ~recurse:false add_element htmldir [] in
  Ok (htmldir, fs)

let odig_theme_list () =
  let themes = Cmd.(atom "odig" % "odoc-theme" % "list" % "--long") in
  let* themes = Os.Cmd.run_out ~trim:true themes in
  let parse_theme p = match String.cut_left ~sep:" " (String.trim p) with
  | None -> Fmt.failwith "%S: could not parse theme" p
  | Some (tn, path) -> Fpath.v ("doc@" ^ tn), Fpath.v path
  in
  Ok (List.map parse_theme (String.cuts_left ~sep:"\n" (String.trim themes)))

let link_themes dir htmldir_contents themes =
  let theme_link dir htmldir_contents (tdir, tcontents) =
    let dir = Fpath.(dir // tdir) in
    let rec loop = function
    | [] ->
        let odoc_theme = Fpath.(dir / "_odoc-theme") in
        Os.Path.copy ~make_path:true
          ~recurse:true ~src:tcontents odoc_theme |> Result.to_failure;
        B0_github.Pages.update ~follow_symlinks:false ~src:(Some dir) tdir
    | f :: fs ->
        if f = "_odoc-theme" then loop fs else
        let src = Fpath.(v ".." / "doc" / f) in
        let dst = Fpath.(dir / f) in
        let force = true and make_path = true in
        Os.Path.symlink ~force ~make_path ~src dst |> Result.to_failure;
        loop fs
    in
    let _bool = Os.Dir.create ~make_path:true dir |> Result.to_failure in
    loop htmldir_contents
  in
  try Ok (List.map (theme_link dir htmldir_contents) themes) with
  | Failure e -> Error e

let pp_updated ppf = function
| false -> Fmt.string ppf "No update to publish on"
| true -> Fmt.string ppf "Published docs on"

let publish tty_cap log_level new_commit remote branch =
  let tty_cap = B0_cli.B0_std.get_tty_cap tty_cap in
  let log_level = B0_cli.B0_std.get_log_level log_level in
  B0_cli.B0_std.setup tty_cap log_level ~log_spawns:Log.Debug;
  Log.if_error ~use:1 @@
  let* versions = versions () in
  let* htmldir, htmldir_contents = odig_html () in
  Log.app (fun m ->
      m "Publishing %a" (Fmt.tty [`Fg `Green] Fpath.pp_quoted) htmldir);
  let* themes = odig_theme_list () in
  Result.join @@
  Os.Dir.with_tmp @@ fun dir ->
  let* theme_updates = link_themes dir htmldir_contents themes in
  let udoc = B0_github.Pages.update ~src:(Some htmldir) (Fpath.v "doc") in
  let updates = B0_github.Pages.nojekyll :: udoc :: theme_updates in
  let* repo = B0_vcs_repo.get () in
  let msg = Fmt.str "Update sample output with %s." versions in
  let amend = not new_commit and force = true in
  let* updated =
    B0_github.Pages.commit_updates repo ~remote ~branch ~amend ~force ~msg
      updates
  in
  Log.app begin fun m ->
      m "[%a] %a %a"
        (Fmt.tty_string [`Fg `Green]) "DONE" pp_updated updated
        B0_vcs_repo.Git.pp_remote_branch
        (remote, B0_github.Pages.default_branch)
  end;
  Ok 0

let main () =
  let open Cmdliner in
  let cmd =
    let new_commit =
      let doc = "Make a new commit, do not amend the last one." in
      Arg.(value & flag & info ["c"; "new-commit"] ~doc)
    in
    let remote =
      let doc = "Publish on remote $(docv)." and docv = "REMOTE" in
      Arg.(value & opt string "origin" & info ["remote"] ~doc ~docv)
    in
    let branch =
      let doc = "Publish on branch $(docv)." and docv = "BRANCH" in
      let default = B0_github.Pages.default_branch in
      Arg.(value & opt string default & info ["b"; "branch"] ~doc ~docv)
    in
    let tty_cap = B0_cli.B0_std.tty_cap () in
    let log_level = B0_cli.B0_std.log_level () in
    let doc = "Updates odig's sample output on GitHub pages" in
    Term.(const publish $ tty_cap $ log_level $ new_commit $
          remote $ branch),
    Term.info "publish" ~version:"%%VERSION%%" ~doc
  in
  Term.exit_status @@ Term.eval cmd

let () = if !Sys.interactive then exit (main ())
