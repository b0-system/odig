(*---------------------------------------------------------------------------
   Copyright (c) 2016 Daniel C. Bünzli. All rights reserved.
   Distributed under the ISC license, see terms at the end of the file.
   %%NAME%% %%VERSION%%
  ---------------------------------------------------------------------------*)

open Bos_setup
open Opkg
open Opkg.Private

let odoc_pkg ~odoc ~force pkg =
  Opkg.Odoc.compile ~odoc ~force pkg >>= fun () ->
  Opkg.Odoc.html ~odoc ~force pkg

let odocs ~odoc ~force conf pkgs =
  Log.on_iter_error_msg Opkg.Pkg.Set.iter (odoc_pkg ~odoc ~force) pkgs;
  Opkg.Odoc.htmldir_css_and_index conf

let api conf odoc force pkgs =
  begin
    Cli.lookup_pkgs conf pkgs
    >>= fun pkgs -> odocs ~odoc ~force conf pkgs
    >>= fun () -> Ok 0
  end
  |> Cli.handle_error

(* Command line interface *)

open Cmdliner

let doc = "Generate package API documentation with odoc"
let man =
  [ `S "DESCRIPTION";
    `P "The $(b,$(tname)) odoc generates the API documentation of a package
        using the cmti files of the package.";
  ] @ Cli.common_man @ Cli.see_also_main_man

let odoc =
  let doc = "The odoc command to use." in
  let env = Arg.env_var "OPKG_ODOC" in
  Arg.(value & opt string "odoc" & info ["odoc"] ~env ~docv:"CMD" ~doc)

let cmd =
  let info = Term.info "odoc" ~sdocs:Cli.common_opts ~doc ~man in
  let term = Term.(const api $ Cli.setup () $ Cli.odoc $ Cli.doc_force $
                   Cli.pkgs_or_all)
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
