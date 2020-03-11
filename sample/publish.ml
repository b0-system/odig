(*---------------------------------------------------------------------------
   Copyright (c) 2019 The odig programmers. All rights reserved.
   Distributed under the ISC license, see terms at the end of the file.
  ---------------------------------------------------------------------------*)

open B00_std

let versions () =
  let run = Os.Cmd.run_out ~trim:true in
  Result.bind (run Cmd.(arg "odig" % "--version")) @@ fun odig ->
  Result.bind (run Cmd.(arg "odoc" % "--version")) @@ fun odoc ->
  Ok (Fmt.str "odig %s and odoc %s" odig odoc)

let odig_html () =
  let cache_path = Cmd.(arg "odig" % "cache" % "path") in
  Result.bind (Os.Cmd.run_out ~trim:true cache_path) @@ fun path ->
  let htmldir = Fpath.(v path / "html") in
  let add_element _ f _ acc = f :: acc in
  Result.bind (Os.Dir.fold ~recurse:false add_element htmldir []) @@ fun fs ->
  Ok (htmldir, fs)

let odig_theme_list () =
  let themes = Cmd.(arg "odig" % "odoc-theme" % "list" % "--long") in
  Result.bind (Os.Cmd.run_out ~trim:true themes) @@ fun themes ->
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
        B00_github.Pages.update ~follow_symlinks:false ~src:(Some dir) tdir
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
  let tty_cap = B00_std_ui.get_tty_cap tty_cap in
  let log_level = B00_std_ui.get_log_level log_level in
  B00_std_ui.setup tty_cap log_level ~log_spawns:Log.Debug;
  Log.if_error ~use:1 @@
  Result.bind (versions ()) @@ fun versions ->
  Result.bind (odig_html ()) @@ fun (htmldir, htmldir_contents) ->
  Log.app (fun m ->
      m "Publishing %a" (Fmt.tty [`Fg `Green] Fpath.pp_quoted) htmldir);
  Result.bind (odig_theme_list ()) @@ fun themes ->
  Result.join @@
  Os.Dir.with_tmp @@ fun dir ->
  Result.bind (link_themes dir htmldir_contents themes) @@ fun theme_updates ->
  let udoc = B00_github.Pages.update ~src:(Some htmldir) (Fpath.v "doc") in
  let updates = B00_github.Pages.nojekyll :: udoc :: theme_updates in
  Result.bind (B00_vcs.get ()) @@ fun repo ->
  let msg = Fmt.str "Update sample output with %s." versions in
  let amend = not new_commit and force = true in
  let pub =
    B00_github.Pages.commit_updates repo ~remote ~branch ~amend ~force ~msg
      updates
  in
  Result.bind pub @@ fun updated ->
  Log.app begin fun m ->
      m "[%a] %a %a"
        (Fmt.tty_string [`Fg `Green]) "DONE" pp_updated updated
        B00_vcs.Git.pp_remote_branch (remote, B00_github.Pages.default_branch)
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
      let default = B00_github.Pages.default_branch in
      Arg.(value & opt string default & info ["b"; "branch"] ~doc ~docv)
    in
    let tty_cap = B00_std_ui.tty_cap () in
    let log_level = B00_std_ui.log_level () in
    let doc = "Updates odig's sample output on GitHub pages" in
    Term.(const publish $ tty_cap $ log_level $ new_commit $
          remote $ branch),
    Term.info "publish" ~version:"%%VERSION%%" ~doc
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
