(*---------------------------------------------------------------------------
   Copyright (c) 2016 The odig programmers. All rights reserved.
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
    Odoc.cmd;
  ]

let main _ = `Help (`Pager, None)

(* Command line interface *)

let main =
  let version = "%%VERSION%%" in
  let doc = "Mine installed OCaml packages" in
  let sdocs = Manpage.s_common_options in
  let man = [
    `S Manpage.s_description;
    `P "$(mname) mines installed OCaml packages. It supports
        package distribution documentation and metadata lookups and
        generates cross-referenced API documentation.";
    `P "See $(b,odig $doc odig) for a tutorial and more details."; `Noblank;
    `P "See $(mname) $(b,conf) for information about $(mname) configuration.";
    `S Manpage.s_see_also;
    `P "Consult $(b,odig doc odig) for a tutorial and more details.";
    `S Manpage.s_bugs;
    `P "Report them, see $(i,%%PKG_HOMEPAGE%%) for contact information." ];
  in
  Term.(ret (const main $ Cli.setup ())),
  Term.info "odig" ~version ~doc ~sdocs ~man

let main () =
  Term.exit @@
  Odig.Private.Log.time (fun _ m -> m "Total time")
  (Term.eval_choice main) cmds

let () = main ()

(*---------------------------------------------------------------------------
   Copyright (c) 2016 The odig programmers

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
