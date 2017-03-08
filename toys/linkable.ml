(*---------------------------------------------------------------------------
   Copyright (c) 2017 Daniel C. Bünzli. All rights reserved.
   Distributed under the ISC license, see terms at the end of the file.
   %%NAME%% %%VERSION%%
  ---------------------------------------------------------------------------*)

open Bos_setup
open Odig

let pkg_names pkg = (* set of cmo and cmx compilation unit names of [pkg] *)
  let add_cmo acc cmo = String.Set.add (Cobj.Cmo.name cmo) acc in
  let add_cmx acc cmx = String.Set.add (Cobj.Cmx.name cmx) acc in
  let cobjs = Pkg.cobjs pkg in
  let acc = String.Set.empty in
  let acc = List.fold_left add_cmo acc (Cobj.cmos cobjs) in
  let acc = List.fold_left add_cmx acc (Cobj.cmxs cobjs) in
  acc

let name_map pkgs =
  let add_pkg pkg m =
    let add_name n m = match String.Map.find n m with
    | None -> String.Map.add n [pkg] m
    | Some pkgs -> String.Map.add n (pkg :: pkgs) m
    in
    String.Set.fold add_name (pkg_names pkg) m
  in
  Pkg.Set.fold add_pkg pkgs String.Map.empty

let log_conflicts warn_error nm =
  let pp_pkg = Fmt.of_to_string Pkg.name in
  let log = if warn_error then Logs.err else Logs.warn in
  let log_conflict n pkgs =
    log (fun m -> m "%s: %a@]" n Fmt.(list ~sep:sp pp_pkg) pkgs)
  in
  let report n pkgs count = match pkgs with
  | [] | [_] -> count
  | _ :: _ -> log_conflict n pkgs; count + 1
  in
  String.Map.fold report nm 0

let linkable conf pkgs warn_error =
  begin
    Cli.lookup_pkgs conf pkgs >>= fun pkgs ->
    let nm = name_map pkgs in
    match log_conflicts warn_error nm with
    | n when n > 0 && warn_error -> Ok 1
    | _ -> Ok 0
  end
  |> Cli.handle_error

(* Command line interface *)

open Cmdliner

let cmd =
  let doc = "Check packages do not define the same compilation unit names." in
  let sdocs = Manpage.s_common_options in
  let exits =
    Term.exit_info 1
      ~doc:"At least two packages define the same compilation unit names
            and $(b,--warn-error) is requested." ::
    Term.default_exits
  in
  let man = [
    `S Manpage.s_description;
    `P "$(mname) checks that no two packages provided on the command line
        (or all of them if none is specified) define the same compilation
        unit names. Those that do are reported on standard out as warnings
        (or errors if $(b,--warn-error) is requested).";
    `P "The set of compilation unit names of a package $(i,PKG) is
        determined by considering the compilation unit names of the
        cmo and cmx files located in the hierarchy rooted at
        $(i,LIBDIR)/$(i,PKG)/. This includes the objects that are
        tucked in `cma` and `cmxa` files."; ]
  in
  Term.(const linkable $ Cli.setup () $ Cli.pkgs_or_all () $ Cli.warn_error),
  Term.info "linkable" ~version:"%%VERSION%%" ~doc ~sdocs ~exits ~man

let main () = Term.exit_status @@ Term.eval cmd
let () = main ()

(*---------------------------------------------------------------------------
   Copyright (c) 2017 Daniel C. Bünzli

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
