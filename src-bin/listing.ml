(*---------------------------------------------------------------------------
   Copyright (c) 2016 Daniel C. Bünzli. All rights reserved.
   Distributed under the ISC license, see terms at the end of the file.
   %%NAME%% %%VERSION%%
  ---------------------------------------------------------------------------*)

open Bos_setup
open Odig
open Odig.Private

let version p =
  Pkg.version p |> Logs.on_error_msg ~level:Logs.Warning ~use:(fun _ -> None)

(* JSON output *)

let json_version = function None -> Json.null | Some p -> Json.str p
let json_pkg pkg =
  Json.(obj @@
        mem "name" (str @@ Pkg.name pkg) ++
        mem "version" (json_version @@ version pkg))

let json_pkgs pkgs =
  let add_pkg_el pkg a = Json.(a ++ el (json_pkg pkg)) in
  Json.(arr @@ Pkg.Set.fold add_pkg_el pkgs empty)

(* Human output *)

let pp_name = Fmt.(styled `None string)
let pp_version =
  let some = Fmt.(styled `Cyan string) in
  let none = Fmt.(styled_unit `Red "?") in
  Fmt.(option ~none some)

let pp_pkg ppf p =
  Fmt.pf ppf "%a %a" pp_name (Pkg.name p) pp_version (version p)

let pp_pkgs = Fmt.(vbox (iter Pkg.Set.iter pp_pkg))

(* Command *)

let list conf pkgs json =
  begin
    Cli.lookup_pkgs conf pkgs >>| fun pkgs ->
    match json with
    | true -> Json.output stdout (json_pkgs pkgs); 0
    | false -> Fmt.pr "%a@." pp_pkgs pkgs; 0
  end
  |> Cli.handle_error

(* Command line interface *)

open Cmdliner

let doc = "List packages"
let man =
  [ `S "DESCRIPTION";
    `P "The $(b,list) command lists the package known to odig.";
  ] @ Cli.common_man @ Cli.see_also_main_man

let cmd =
  let info = Term.info "list" ~sdocs:Cli.common_opts ~doc ~man in
  let term = Term.(const list $ Cli.setup () $ Cli.pkgs_or_all $ Cli.json) in
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
