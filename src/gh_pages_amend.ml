(*---------------------------------------------------------------------------
   Copyright (c) 2019 The odig programmers. All rights reserved.
   SPDX-License-Identifier: ISC
  ---------------------------------------------------------------------------*)

open B0_std

let pp_updated ppf = function
| false -> Fmt.string ppf "No update to publish on"
| true -> Fmt.string ppf "Published docs on"

let get_msg ~src ~dst = function
| Some m -> m
| None ->
    Fmt.str "Update %a\n\nWith contents of %a"
      Fpath.pp_quoted dst Fpath.pp_quoted src

let publish ~amend ~msg ~remote ~branch preserve_symlinks cname_file src dst =
  let follow_symlinks = not preserve_symlinks in
  let dst_upd = B0_github.Pages.update ~follow_symlinks (Some src) ~dst in
  let rupdates = [ B0_github.Pages.nojekyll; dst_upd ] in
  let rupdates = match cname_file with
  | None -> rupdates
  | Some f ->
      B0_github.Pages.update (Some f) ~dst:(Fpath.v "CNAME") :: rupdates
  in
  let updates = List.rev rupdates in
  Result.bind (B0_vcs_repo.get ()) @@ fun repo ->
  let force = true in
  B0_github.Pages.commit_updates
    repo ~amend ~force ~remote ~branch ~msg updates

let publish_cmd
    color log_level new_commit remote branch msg preserve_symlinks
    cname_file src dst
  =
  let styler = B0_std_cli.get_styler color in
  Fmt.set_styler styler;
  Log.if_error ~use:1 @@
  let msg = get_msg ~src ~dst msg in
  let amend = not new_commit in
  let pub =
    publish ~amend ~msg ~remote ~branch preserve_symlinks cname_file src dst
  in
  Result.bind pub @@ fun updated ->
  Log.stdout begin fun m ->
    m "[%a] %a %a"
      (Fmt.st [`Fg `Green]) "DONE" pp_updated updated
      B0_vcs_repo.Git.pp_remote_branch (remote, branch)
  end;
  Ok 0

let main () =
  let open Cmdliner in
  let some_path = Arg.some B0_std_cli.fpath in
  let cmd =
    let preserve_symlinks =
      let doc = "Do not follow symlinks in $(i,SRC), preserve them." in
      Arg.(value & flag & info ["preserve-symlinks"] ~doc)
    in
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
    let msg =
      let doc = "$(docv) is the commit message. If unspecified one is
                 made up using $(i,SRC) and $(i,DST)."
      in
      let docv = "MSG" in
      Arg.(value & opt (some string) None & info ["m"; "message"] ~doc ~docv)
    in
    let src =
      let doc = "$(docv) is the directory to publish." in
      Arg.(required & pos 0 some_path None & info [] ~doc ~docv:"SRC")
    in
    let dst =
      let doc = "$(docv) is the directory relative to the root of the \
                 repository checkout which is replaced by $(i,SRC)'s \
                 contents. Use . to publish at the root."
      in
      Arg.(required & pos 1 some_path None & info [] ~doc ~docv:"DST")
    in
    let cname_file =
      let doc = "If specified the contents of $(docv) is copied over to the \
                 path $(i,CNAME) at the root of the branch."
      in
      Arg.(value & opt some_path None & info ["cname-file"] ~doc ~docv:"FILE")
    in
    let color = B0_std_cli.color () in
    let log_level = B0_std_cli.log_level () in
    let doc = "Publish directories on GitHub pages" in
    let man = [
      `S Manpage.s_description;
      `P "$(mname) replaces $(b,DST) by the contents of $(b,SRC) on the
          gh-pages branch of the current repository origin remote by
          amending the last commit.";
      `P "The various edge cases (no branch, no last commit, etc.)
          should be handled correctly. A $(b,.nojekyll) file is also
          unconditionally added at the root of the branch.";
      `S Manpage.s_bugs;
      `P "Report them, see $(i,%%PKG_HOMEPAGE%%) for contact information." ];
    in
    Cmd.v (Cmd.info "gh-pages-amend" ~version:"%%VERSION%%" ~doc ~man)
      Term.(const publish_cmd $ color $ log_level $ new_commit $ remote $
            branch $ msg $ preserve_symlinks $ cname_file $ src $ dst)
  in
  exit (Cmd.eval' cmd)

let () = if !Sys.interactive then () else main ()
