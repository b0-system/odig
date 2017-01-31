(*---------------------------------------------------------------------------
   Copyright (c) 2016 Daniel C. Bünzli. All rights reserved.
   Distributed under the ISC license, see terms at the end of the file.
   %%NAME%% %%VERSION%%
  ---------------------------------------------------------------------------*)

open Bos_setup
open Odig
open Odig.Private

let cmi_digests pkgs =
  let add_pkg pkg acc =
    let add_digest acc cmi = String.Set.add (Cobj.Cmi.digest cmi) acc in
    List.fold_left add_digest acc (Cobj.cmis (Pkg.cobjs pkg))
  in
  Pkg.Set.fold add_pkg pkgs String.Set.empty

let graph_pkg_cmis conf pkgs =
  Pkg.conf_cobj_index conf >>= fun index ->
  let rec deps seen pkgs acc todo = match String.Set.choose todo with
  | None -> seen, pkgs, acc
  | Some digest ->
      let rec add_cmis pkgs acc todo = function
      | [] -> pkgs, acc, todo
      | ((`Pkg pkg), cmi) :: cmis ->
          let rec add_dep acc todo = function
          | (_, Some dep) :: deps ->
              let digid = Digest.to_hex digest in
              let depid = Digest.to_hex dep in
              let acc = Dot.(acc ++ edge digid depid) in
              let todo =
                if String.Set.mem dep seen then todo else
                String.Set.add dep todo
              in
              add_dep acc todo deps
          | _ -> acc, todo
          in
          let acc, todo = add_dep acc todo (Cobj.Cmi.deps cmi) in
          let pkgs = Pkg.Set.add pkg pkgs in
          add_cmis pkgs acc todo cmis
      in
      let todo = String.Set.remove digest todo in
      let seen = String.Set.add digest seen in
      let cmis = Cobj.Index.cmis_for_interface index (`Digest digest) in
      let pkgs, acc, todo = add_cmis pkgs acc todo cmis in
      deps seen pkgs acc todo
  in
  let nodes digests pkgs =
    let add_pkg pkg acc =
      let add_node acc cmi =
        let digest = Cobj.Cmi.digest cmi in
        if not (String.Set.mem digest digests) then acc else
        let name = Cobj.Cmi.name cmi in
        let id = Digest.to_hex digest in
        Dot.(acc ++ node ~atts:(label name) id)
      in
      let cmis = Cobj.cmis (Pkg.cobjs pkg) in
      let nodes = List.fold_left add_node Dot.empty cmis in
      let name = Pkg.name pkg in
      let gatts = Dot.(atts `Graph (label name)) in
      Dot.(acc ++ subgraph ~id:("cluster_" ^ name) (nodes ++ gatts))
    in
    Pkg.Set.fold add_pkg pkgs Dot.empty
  in
  let cmis = cmi_digests pkgs in
  let digests, pkgs, deps =
    deps String.Set.empty Pkg.Set.empty Dot.empty cmis
  in
  let nodes = nodes digests pkgs in
  let graph_pkgs = Dot.((* atts `Graph (att "rankdir" "LR") ++ *) deps ++
                             nodes)
  in
  Ok Dot.(graph ~id:"cmi deps" `Digraph graph_pkgs)

let graph_pkg_deps conf pkgs =
  let dep_edge pkg dep acc =
    Dot.(acc ++ edge (Pkg.name pkg) (Pkg.name dep))
  in
  let rec add_deps seen acc todo = match Pkg.Set.choose todo with
  | None -> acc
  | Some pkg ->
      let todo = Pkg.Set.remove pkg todo in
      if Pkg.Set.mem pkg seen then add_deps seen acc todo else
      let seen = Pkg.Set.add pkg seen in
      let deps = Pkg.(field ~err:String.Set.empty deps pkg) in
      let pkgs, _ = Pkg.find_set conf deps in
      let todo = Pkg.Set.union todo pkgs in
      let acc = Dot.(acc ++ node (Pkg.name pkg)) in
      let acc = Pkg.Set.fold (dep_edge pkg) pkgs acc in
      add_deps seen acc todo
  in
  let graph_pkgs pkgs =
    Dot.(atts `Graph (att "rankdir" "LR") ++
              add_deps Pkg.Set.empty Dot.empty pkgs)
  in
  Ok Dot.(graph ~id:"pkg deps" `Digraph (graph_pkgs pkgs))

let out g = g >>= fun g -> Dot.output stdout g; Ok 0

let graph conf kind pkgs =
  begin
    let pkgs = match pkgs with [] -> `All | pkgs -> `Pkgs pkgs in
    Cli.lookup_pkgs conf pkgs
    >>= fun pkgs -> match kind with
    | `Pkg_deps -> out @@ graph_pkg_deps conf pkgs
    | `Cmi_deps -> out @@ graph_pkg_cmis conf pkgs
(*    | `Cmo_deps -> failwith "TODO" *)
  end
  |> Cli.handle_error

(* Command line interface *)

open Cmdliner

let doc = "Generate graphs from the package install data"
let man =
  [ `S "SYNOPSIS";
    `P "$(mname) $(tname) $(i,KIND) [$(i,OPTION)]... [$(i,PKG)]...";
    `S "DESCRIPTION";
    `P "The $(tname) generates dot files according to
        $(i,KIND). If no packages are specified, operates on all packages.";
    `P "EXAMPLES";
    `Pre " odig graph pkg-deps | dot -Tsvg > /tmp/d.svg && browse /tmp/d.svg";
    `S "ACTIONS";
    `I ("$(b,pkg)", "Graph of declared, installed and recognized \
                     package dependencies.");
    `I ("$(b,cmi)", "Graph of cmi dependencies");
(*    `I ("$(b,cmo)", "Graph of potential cmo dependencies."); *)
  ] @ Cli.common_man @ Cli.see_also_main_man

let kind =
  let kind = [ "pkg-deps", `Pkg_deps; "cmi-deps", `Cmi_deps;
               (* "cmo-deps", `Cmo_deps; *)]
  in
  let doc = strf "The kind of graph to generate. $(docv) must be one of %s."
      (Arg.doc_alts_enum kind)
  in
  let kind = Arg.enum kind in
  Arg.(required & pos 0 (some kind) None & info [] ~doc ~docv:"KIND")

let cmd =
  let info = Term.info "graph" ~sdocs:Cli.common_opts ~doc ~man in
  let term = Term.(const graph $ Cli.setup () $ kind $
                   Cli.pkgs ~right_of:0 ()) in
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
