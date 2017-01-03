(*---------------------------------------------------------------------------
   Copyright (c) 2016 Daniel C. Bünzli. All rights reserved.
   Distributed under the ISC license, see terms at the end of the file.
   %%NAME%% %%VERSION%%
  ---------------------------------------------------------------------------*)

let odig_manual = "Odig manual"
let version = "%%VERSION%%"

(* Help manuals *)

let basics =
  ("OPKG-BASICS", 7, "", version, odig_manual),
  [ `S "NAME";
    `P "odig-basics - short introduction to odig";
    `S "DESCRIPTION";
    `P "odig helps you to access information about installed OCaml
        packages. The following describes the basics of the
        tool, more information about packaging conventions can
        be found in odig-packaging(7).";
    `S "PACKAGE LIST";
    `P "The list of packages recognized by odig can be obtained with:";
    `Pre " odig list";
    `S "PACKAGE DISTRIBUTION DOCUMENTATION AND METADATA";
    `P "odig provides a few commands that make it easy to lookup
        the  readme, change log and license files of packages.
        Here are a few sample invocation on the package named 'bos':";
    `Pre " odig readme bos";`Noblank;
    `Pre " odig changes bos";`Noblank;
    `Pre " odig license bos";
    `P "If the package properly installed its OPAM metadata file you can
        also quickly get access to the issues, homepage, or
        online documentation pages of a package. The following commands
        opens them in your browser:";
    `Pre " odig issues bos"; `Noblank;
    `Pre " odig homepage bos"; `Noblank;
    `Pre " odig online-doc bos";
    `P "See the help of individual commands for more details and options.";
    `S "OCAMLDOC PACKAGE API DOCUMENTATION";
    `P "Package API documentation can be generated on a best-effort basis
        with ocamldoc by issuing:";
    `Pre " odig ocamldoc      # Generate API docs for all packages"; `Noblank;
    `Pre " odig ocamldoc bos  # Generate API docs for package bos";
    `P "To open the documentation index or the documentation of
        a package in your browser use:";
    `Pre " odig doc      # Package index "; `Noblank;
    `Pre " odig doc bos  # API doc for package bos";
    `S "TOPLEVEL SUPPORT (EXPERIMENTAL)";
    `P "Odig provides support to automatically load modules and their
        dependencies. In a toplevel simply invoke:";
    `Pre "# #use \"odig.top\"";
    `P "You may want to add that line to your ~/.ocamlinit file. Here
        are a few invocations, note that those always lookup the recursive
        dependencies.";
    `Pre "# Odig.load \"Gg\"    (* Load module Gg *)"; `Noblank;
    `Pre "# Odig.load_libs () (* Load locally build libraries *)"; `Noblank;
    `Pre "# Odig.load_pkg \"p\" (* Load all libraries of package p *)";
    `P "Consult the API in `odig doc odig` for more information.";
    `S "SEE ALSO";
    `P "odig(1), odig-packaging(7)"; ]

let packaging =
  ("OPKG-PACKAGING", 7, "", version, odig_manual),
  [ `S "NAME";
    `P "odig-packaging - packaging conventions for odig";
    `S "DESCRIPTION";
    `P "The following describes the conventions package installs
        should follow to maximize odig's mining capabilities.";
    `S "PACKAGE INSTALL STRUCTURE AND EXISTENCE";
    `P "odig assumes all OCaml packages are installed in a library prefix
        called $(i,LIBDIR) and have their distribution documentation installed
        in a library prefix called $(i,DOCDIR).";
    `P "For a package named $(i,PKG) to be recognized by odig $(i,PKG)
        must be a valid OPAM package name and one of the following paths
        must exist:";
    `P "$(i,LIBDIR)/$(i,PKG)/opam";`Noblank;
    `P "$(i,LIBDIR)/$(i,PKG)/META"; `Noblank;
    `P "$(i,LIBDIR)/$(i,PKG)/caml (deprecated)";
    `P "If neither exists $(i,LIBDIR)/$(i,PKG) is ignored by odig and the
        package $(i,PKG) does not exist.";
    `P "For each package $(i,PKG) its distribution documentation (readme,
        license, change log, sample code, etc.) is looked up in the directory
        $(i,DOCDIR)/$(i,PKG).";
    `P "Typically the values of $(i,LIBDIR) and $(i,DOCDIR) will
        be `opam config var lib` and `opam config var doc`. However
        odig is not tied to OPAM, the only assumption made by odig is
        that the above install structure is followed.";
    `S "METADATA RECOGNITION";
    `P "Package metadata for $(i,PKG) is always read from
        $(i,LIBDIR)/$(i,PKG)/opam which must be a valid OPAM
        file. If present, the following fields are consulted and used
        by odig in various context and/or commands.";
    `I ("authors:", "The authors, $(b,authors) command");
    `I ("bug-reports:", "The issue tracker URI, $(b,issues) command");
    `I ("deps:, depopts:", "The dependencies, $(b,deps) command");
    `I ("dev-repo:", "The source repository URI, $(b,repo) command");
    `I ("doc:", "The online documentation URI, $(b,online-doc) command");
    `I ("homepage:", "The homepage URI, $(b,homepage) command");
    `I ("license:", "License tags, $(b,license -t) command");
    `I ("maintainers:", "The maintainers, $(b,maintainers) command");
    `I ("tags:", "Classification tags, $(b,tags) command");
    `I ("version:", "The version string, $(b,version) command");
    `S "DISTRIBUTION DOCUMENTATION RECOGNITION";
    `P "The distribution documentation for a package $(i,PKG) is determined
        by $(b,caseless) matching files in $(i,DOCDIR)/$(i,PKG).
        The following matches are performed; multiple files
        are allowed to match and * denotes zero or more characters.";
    `I ("$(i,DOCDIR)/$(i,PKG)/README*", "readmes, $(b,readme) command");
    `I ("$(i,DOCDIR)/$(i,PKG)/CHANGE* or $(i,DOCDIR)/$(i,PKG)/HISTORY*",
         "change logs, $(b,changes) command");
    `I ("$(i,DOCDIR)/$(i,PKG)/LICENSE*", "license, $(b,license) command");
    `S "ODOC PACKAGE API DOCUMENTATION";
    `P "The odoc API documentation of a package $(i,PKG) is generated
        by considering all cmi files in the path hierarchy rooted at
        $(i,LIBDIR)/$(i,PKG).";
    `P "Any cmi file installed by the package is considered to be part of
        the package API. For each of these files if a corresponding
        cmti file is found at the same location it used to generate
        the documentation; if not, an existing cmt file is used and
        lacking this the cmi file is used as a last resort.";
    `P  "FIXME say something about multiple cmi files with the same name";
    `S "OCAMLDOC PACKAGE API DOCUMENTATION";
    `P "The ocamldoc API documentation of a package $(i,PKG) is generated
        by considering all mli files in the path hierarchy rooted at
        $(i,LIBDIR)/$(i,PKG).";
    `P "Any mli file installed by the package is considered to be part of
        the package API. For each of these files its corresponding cmi must
        also be installed at the same location.";
    `P "If a package defines more than one mli for a given toplevel
        compilation unit name the one residing at the lexicographically
        shorter path is taken to be part of the API documentation.";
    `S "TOPLEVEL SUPPORT (EXPERIMENTAL)";
    `P "After Odig loads a library named `lib` it loads a file
        named `lib_top_init.ml` at the same location if it exists.";
    `S "SEE ALSO";
    `P "odig(1), odig-basics(7)"; ]

let conf =
  ("OPKG-CONF", 7, "", version, odig_manual),
  [ `S "NAME";
    `P "odig-conf - odig configuration file";
    `S "DESCRIPTION";
    `P "The odig configuration file is undocumented for now.";
    `S "SEE ALSO";
    `P "odig(1)"; ]

(* Help command *)

let pages =
  [ "basics", basics;
    "packaging", packaging;
    "conf", conf; ]

let help man_format topic commands = match topic with
| None -> `Help (man_format, None)
| Some topic ->
    let topics = "topics" :: commands @ (List.map fst pages) in
    let topics = List.sort compare topics in
    let conv, _ = Cmdliner.Arg.enum (List.rev_map (fun s -> (s, s)) topics) in
    match conv topic with
    | `Error e -> `Error (false, e)
    | `Ok t when List.mem t commands -> `Help (man_format, Some t)
    | `Ok t when t = "topics" ->
        Fmt.pr "@[<v>%a@]@." Fmt.(list string) topics;
        `Ok 0
    | `Ok t ->
        let man = try List.assoc t pages with Not_found -> assert false in
        Fmt.pr "%a" (Cmdliner.Manpage.print man_format) man;
        `Ok 0

(* Command line interface *)

open Cmdliner

let topic =
  let doc = "The topic to get help on, `topics' lists the topic." in
  Arg.(value & pos 0 (some string) None & info [] ~docv:"TOPIC" ~doc)

let doc = "Show help about odig"
let man =
  [ `S "DESCRIPTION";
    `P "The $(b,$(tname)) command shows help about odig.";
    `P "Use `topics' as $(i,TOPIC) to get a list of topics.";
  ] @ Cli.see_also_main_man

let cmd =
  let info = Term.info "help" ~doc ~man in
  let t = Term.(ret (const help $ Term.man_format $ topic $
                      Term.choice_names))
  in
  (t, info)

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
