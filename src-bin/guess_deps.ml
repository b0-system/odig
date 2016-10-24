(*---------------------------------------------------------------------------
   Copyright (c) 2016 Daniel C. Bünzli. All rights reserved.
   Distributed under the ISC license, see terms at the end of the file.
   %%NAME%% %%VERSION%%
  ---------------------------------------------------------------------------*)

open Bos_setup
open Odig

let pp_packages =
  let pp_package = Fmt.using Pkg.name Fmt.string in
  Fmt.vbox (Pkg.Set.pp pp_package)

let index_digests cobjs =
  (* FIXME we should keep indices separate according to the type of obj *)
  let add get_digest get_deps (self, deps) obj =
    let add_dep (digests, names) (n, d) = match d with
    | None -> digests, String.Set.add n names
    | Some d -> String.Set.add d digests, names
    in
    let deps = List.fold_left add_dep deps (get_deps obj) in
    String.Set.add (get_digest obj) self, deps
  in
  let add_cmi = add Cobj.Cmi.digest Cobj.Cmi.deps in
  let add_cmo = add Cobj.Cmo.cmi_digest Cobj.Cmo.cmi_deps in
  let add_cmx =
    let deps cmx =
      List.rev_append (Cobj.Cmx.cmi_deps cmx) (Cobj.Cmx.cmx_deps cmx)
    in
    add Cobj.Cmx.digest deps
  in
  let acc = String.Set.empty, (String.Set.empty, String.Set.empty) in
  let acc = List.fold_left add_cmi acc (Cobj.cmis cobjs) in
  let acc = List.fold_left add_cmo acc (Cobj.cmos cobjs) in
  let acc = List.fold_left add_cmx acc (Cobj.cmxs cobjs) in
  acc

let match_digests index (self, (digests, _)) =
  let add_pkgs d acc =
    if String.Set.mem d self then acc else
    let cmis, _, cmos, cmxs = Cobj.Index.query index (`Digest d) in
    (* FIXME warn multiple *)
    let add_pkg acc ((`Pkg pkg), _) = Pkg.Set.add pkg acc in
    let acc = List.fold_left add_pkg acc cmis in
    let acc = List.fold_left add_pkg acc cmos in
    let acc = List.fold_left add_pkg acc cmxs in
    acc
  in
  String.Set.fold add_pkgs digests Pkg.Set.empty

let guess_deps index cobjs =
  let indices = index_digests cobjs in
  match_digests index indices

let guess_deps conf build_dir =
  begin
    Pkg.conf_cobj_index conf
    >>= fun index -> Ok (Cobj.set_of_dir build_dir)
    >>= fun cobjs -> Ok (guess_deps index cobjs)
    >>= fun pkgs -> Ok (Fmt.pr "%a@." pp_packages pkgs)
    >>= fun () -> Ok 0
  end
  |> Cli.handle_error

(* Command line interface *)

open Cmdliner

let build_dir =
  let doc = "The directory $(docv) with build artefacts" in
  let docv = "BUILD_DIR" in
  Arg.(value & pos 0 Cli.path_arg (Fpath.v "_build") & info [] ~doc ~docv)

let doc = "Guess packages used by a build"
let man =
  [ `S "DESCRIPTION";
    `P "The $(b,guess-deps) outputs a guess of the packages used by
        a build directory.";
  ] @ Cli.common_man @ Cli.see_also_main_man

let cmd =
  let info = Term.info "guess-deps" ~sdocs:Cli.common_opts ~doc ~man in
  let term = Term.(const guess_deps $ Cli.setup () $ build_dir) in
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
