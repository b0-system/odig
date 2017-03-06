(*---------------------------------------------------------------------------
   Copyright (c) 2016 Daniel C. Bünzli. All rights reserved.
   Distributed under the ISC license, see terms at the end of the file.
   %%NAME%% %%VERSION%%
  ---------------------------------------------------------------------------*)

open Cmdliner

let cmds =
  [
    Cache.cmd;
    Cobjs.cmd;
    Distrib_doc.changes_cmd;
    Distrib_doc.license_cmd;
    Distrib_doc.readme_cmd;
    Doc.cmd;
    Graf.cmd;
    Guess_deps.cmd;
    Help.cmd;
    Listing.cmd;
    Metadata.authors_cmd;
    Metadata.deps_cmd;
    Metadata.maintainers_cmd;
    Metadata.tags_cmd;
    Metadata.version_cmd;
    Metadata_uri.homepage_cmd;
    Metadata_uri.issues_cmd;
    Metadata_uri.online_doc_cmd;
    Metadata_uri.repo_cmd;
    Ocamldoc.cmd;
    Odoc.cmd;
  ]

let main _ = `Help (`Pager, None)

(* Command line interface *)

let main =
  let version = "%%VERSION%%" in
  let doc = "Mine installed OCaml packages" in
  let sdocs = Manpage.s_common_options in
  let man_xrefs =
    [ `Page ("odig-basics", 7); `Page ("odig-packaging", 7) ]
  in
  let man = [
    `S "DESCRIPTION";
    `P "$(mname) mines installed OCaml packages. It supports
        package distribution documentation and metadata lookups and
        generates cross-referenced API documentation.";
    `P "Use '$(mname) help basics' for understanding the basics.";
    `Noblank;
    `P "Use '$(mname) help packaging' for packaging conventions.";
    `Noblank;
    `P "Use '$(mname) help conf' for information about odig
        configuration.";
    `Noblank;
    `P "Use '$(mname) help $(i,COMMAND)' for information about
        $(i,COMMAND).";
    `S "IMPORTANT WARNING";
    `P "$(mname) is a usable work in progress. Command line interfaces
        may change without notice in the future.";
    `S "BUGS";
    `P "Report them, see $(i,%%PKG_HOMEPAGE%%) for contact information.";
    `S "AUTHOR";
    `P "Daniel C. Buenzli, $(i,http://erratique.ch)" ]
  in
  Term.(ret (const main $ Cli.setup ())),
  Term.info "odig" ~version ~doc ~sdocs ~man_xrefs ~man

let main () =
  Term.exit @@
  Odig.Private.Log.time (fun _ m -> m "Total time")
  (Term.eval_choice main) cmds

let () = main ()

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
