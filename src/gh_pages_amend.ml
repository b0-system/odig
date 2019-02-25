(*---------------------------------------------------------------------------
   Copyright (c) 2019 The odig programmers. All rights reserved.
   Distributed under the ISC license, see terms at the end of the file.
   %%NAME%% %%VERSION%%
  ---------------------------------------------------------------------------*)

open B0_std

let publish ~amend ~msg ~remote ~branch preserve_symlinks src dst =
  let follow_symlinks = not preserve_symlinks in
  let update = B0_github.Pages.update ~follow_symlinks ~src:(Some src) dst in
  let updates = [ update; B0_github.Pages.nojekyll ] in
  Result.bind (B0_vcs.get ()) @@ fun repo ->
  B0_github.Pages.commit_updates
    repo ~amend ~force:true ~remote ~branch ~msg updates

let pp_updated ppf = function
| false -> Fmt.string ppf "No update to publish on"
| true -> Fmt.string ppf "Published docs on"

let publish_cmd () new_commit remote branch msg preserve_symlinks src dst =
  let msg = match msg with
  | Some m -> m
  | None -> Fmt.str "Update %a\n\nWith contents of %a" Fpath.pp dst Fpath.pp src
  in
  let amend = not new_commit in
  let pub = publish ~amend ~msg ~remote ~branch preserve_symlinks src dst in
  let ret = Result.bind pub @@ fun updated ->
    Log.app begin fun m ->
      m "[%a] %a %a"
        (Fmt.tty_string [`Fg `Green]) "DONE" pp_updated updated
        B0_vcs.Git.pp_remote_branch (remote, branch)
    end;
    Ok 0
  in
  Log.if_error ~use:1 ret

let main () =
  let open Cmdliner in
  let some_path = Arg.some B0_ui.Cli.Arg.path in
  let cmd =
    let preserve_symlinks =
      let doc = "Do not follow symlinks in $(v,SRC), preserve them." in
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
                 made up using $(b,SRC) and $(b,DST)."
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
    Term.(const publish_cmd $ B0_ui.Cli.B0_std.setup () $ new_commit $ remote $
          branch $ msg $ preserve_symlinks $ src $ dst),
    Term.info "gh-pages-amend" ~version:"%%VERSION%%" ~doc ~man
  in
  Term.exit_status @@ Term.eval cmd

let () = main ()

(*---------------------------------------------------------------------------
   Copyright (c) 2019 The odig programmers

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
