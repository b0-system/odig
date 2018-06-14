(*---------------------------------------------------------------------------
   Copyright (c) 2016 The odig programmers. All rights reserved.
   Distributed under the ISC license, see terms at the end of the file.
   %%NAME%% %%VERSION%%
  ---------------------------------------------------------------------------*)

open Bos_setup
open Odig.Private

let odoc_pkg ~odoc ~force pkg =
  Log.app (fun m -> m "Processing %s." (Pkg.name pkg));
  Odig.Odoc.compile ~odoc ~force pkg >>= fun () ->
  Odig.Odoc.html ~odoc ~force pkg

let odocs ~odoc ~force conf pkgs =
  Log.on_iter_error_msg Odig.Pkg.Set.iter (odoc_pkg ~odoc ~force) pkgs;
  Odig.Odoc.htmldir_css_and_index conf

let api conf odoc force docdir_href pkgs =
  begin
    let conf = Odig.Conf.with_conf ?docdir_href conf in
    OS.Cmd.must_exist odoc
    >>= fun odoc -> Cli.lookup_pkgs conf pkgs
    >>= fun pkgs -> odocs ~odoc ~force conf pkgs
    >>= fun () -> Ok 0
  end
  |> Cli.handle_error

(* Command line interface *)

open Cmdliner

let odoc =
  let doc = "The odoc command to use." in
  let env = Arg.env_var "ODIG_ODOC" in
  Arg.(value & opt string "odoc" & info ["odoc"] ~env ~docv:"CMD" ~doc)

let cmd =
  let doc = "Generate package API documentation with odoc" in
  let sdocs = Manpage.s_common_options in
  let exits = Cli.exits in
  let man_xrefs = [ `Main ] in
  let man = [
    `S "DESCRIPTION";
    `P "The $(tname) odoc generates the API documentation of a package
        using the cmti files of the package." ]
  in
  Term.(const api $ Cli.setup () $ Cli.odoc $ Cli.doc_force $
        Cli.docdir_href $ Cli.pkgs_or_all ()),
  Term.info "odoc" ~doc ~sdocs ~exits ~man_xrefs ~man

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
