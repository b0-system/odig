(*---------------------------------------------------------------------------
   Copyright (c) 2016 Daniel C. Bünzli. All rights reserved.
   Distributed under the ISC license, see terms at the end of the file.
   %%NAME%% %%VERSION%%
  ---------------------------------------------------------------------------*)

open Bos_setup
open Odig
open Odig.Private

let ocamldoc_pkg ~ocamldoc ~force pkg =
  Log.app (fun m -> m "Processing %s." (Pkg.name pkg));
  Odig.Ocamldoc.compile ~force ~ocamldoc pkg  >>= fun () ->
  Odig.Ocamldoc.html ~force ~ocamldoc pkg

let ocamldocs ~ocamldoc ~force conf pkgs =
  Log.on_iter_error_msg Pkg.Set.iter (ocamldoc_pkg ~force ~ocamldoc) pkgs;
  Odig.Ocamldoc.htmldir_css_and_index conf

let api_doc conf ocamldoc force docdir_href pkgs =
  begin
    let conf = Odig.Conf.with_conf ?docdir_href conf in
    Cli.lookup_pkgs conf pkgs
    >>= fun pkgs -> ocamldocs ~ocamldoc ~force conf pkgs
    >>= fun () -> Ok 0
  end
  |> Cli.handle_error

(* Command line interface *)

open Cmdliner

let doc = "Generate package API documentation with ocamldoc"
let man =
  [ `S "DESCRIPTION";
    `P "The $(tname) command generates the API documentation of
        a package via its mli files.";
  ] @ Cli.common_man @ Cli.see_also_main_man

let cmd =
  let info = Term.info "ocamldoc" ~sdocs:Cli.common_opts ~doc ~man in
  let term = Term.(const api_doc $ Cli.setup () $ Cli.ocamldoc $
                   Cli.doc_force $ Cli.docdir_href $ Cli.pkgs_or_all)
  in
  term, info

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
