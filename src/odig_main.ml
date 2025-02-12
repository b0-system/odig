(*---------------------------------------------------------------------------
   Copyright (c) 2018 The odig programmers. All rights reserved.
   SPDX-License-Identifier: ISC
  ---------------------------------------------------------------------------*)

open B0_std
open Result.Syntax
open Odig_support

(* Exit codes *)

module Exit = struct
  let no_such_name = 1
  let err_uri = 2
  let some_error = Cmdliner.Cmd.Exit.some_error
end

(* Commonalities *)

let find_pkgs conf = function
| [] -> Ok (Conf.pkgs conf)
| ns ->
    let pkgs = Conf.pkgs conf in
    let by_name = Pkg.by_names pkgs in
    let add_name (fnd, miss) n = match String.Map.find n by_name with
    | exception Not_found -> (fnd, n :: miss)
    | pkg -> (pkg :: fnd, miss)
    in
    let fnd, miss = List.fold_left add_name ([], []) ns in
    match miss with
    | [] -> Ok (List.rev fnd)
    | miss ->
        let exists yield = List.iter yield (List.rev_map Pkg.name pkgs) in
        let add_error acc n =
          let kind = Fmt.any "package" in
          let unknown = Fmt.(unknown' ~kind Fmt.string ~hint:did_you_mean) in
          let err = Fmt.str "%a" unknown (n, String.spellcheck exists n) in
          err :: acc
        in
        Error (String.concat "\n" (List.fold_left add_error [] miss))

let odoc_gen conf
    ~force ~index_title ~index_intro ~index_toc ~pkg_deps ~tag_index pkgs
  =
  Log.stdout (fun m -> m "Updating documentation, this may take some time...");
  Odig_odoc.gen
    conf ~force ~index_title ~index_intro ~index_toc ~pkg_deps ~tag_index pkgs

(* Commands *)

let browse_cmd conf background browser field pkg_names =
  Log.if_error ~use:Exit.no_such_name @@
  let* pkgs = find_pkgs conf pkg_names in
  Log.if_error' ~use:Exit.some_error @@
  let* browser = B0_web_browser.find ?cmd:browser () in
  let get_uris = match field with
  | `Homepage -> Opam.homepage
  | `Issues -> Opam.bug_reports
  | `Online_doc -> Opam.doc
  in
  let pkgs = Opam.query pkgs in
  let uris = List.concat (List.map (fun (_, o) -> get_uris o) pkgs) in
  let rec loop exit = function
  | [] -> Ok exit
  | u :: us ->
      match B0_web_browser.show ~background ~prefix:false browser u with
      | Error e -> Log.err (fun m -> m "%s" e); loop Exit.err_uri us
      | Ok () -> loop exit us
  in
  loop 0 uris

let conf_cmd conf = Fmt.pr "%a@." Conf.pp conf; 0

let cache_cmd conf = function
| `Path -> Fmt.pr "%a@." Fpath.pp_unquoted (Conf.cache_dir conf); 0
| `Clear ->
    let dir = Conf.cache_dir conf in
    Log.stdout begin fun m ->
      m "Deleting %a, this may take some time..."
        (Fmt.st' [`Fg `Green] Fpath.pp_quoted) dir
    end;
    Log.if_error ~use:Exit.some_error @@
    let* _del = Os.Path.delete ~recurse:true dir in
    Ok 0
| `Trim ->
    let b0_cache_dir = Conf.b0_cache_dir conf in
    Log.if_error ~use:Exit.some_error @@
    let* exists = Os.Dir.exists b0_cache_dir in
    if not exists then Ok 0 else
    let pct = 50 and max_byte_size = max_int in
    let* c = B0_zero.File_cache.make b0_cache_dir in
    let* () = B0_zero.File_cache.trim_size c ~max_byte_size ~pct in
    Ok 0

let doc_cmd conf background browser pkg_names update no_update show_files =
  let exists f = Os.File.exists f |> Log.if_error ~use:false in
  Log.if_error ~use:Exit.no_such_name @@
  let* pkgs = match pkg_names with
  | [] -> Ok []
  | ns -> find_pkgs conf pkg_names
  in
  Log.if_error' ~use:Exit.some_error @@
  let* browser = B0_web_browser.find ?cmd:browser () in
  let* files = match pkgs with
  | [] ->
      let root_index = Fpath.(Conf.html_dir conf / "index.html") in
      begin match exists root_index with
      | true when not update || no_update -> Ok [root_index]
      | false when no_update -> Error "No doc found. Try with 'odig doc -u'."
      | _ ->
          let pkgs = Conf.pkgs conf in
          let index_title = None and index_intro = None and index_toc = None in
          let force = false and pkg_deps = true and tag_index = true in
          let* () =
            odoc_gen conf ~force ~index_title ~index_intro ~index_toc
              ~pkg_deps ~tag_index pkgs
          in
          Ok [root_index]
      end
  | pkgs ->
      let index p = Fpath.(Conf.html_dir conf / Pkg.name p / "index.html") in
      let files = List.rev (List.rev_map index pkgs) in
      match List.find_all (fun f -> not (exists f)) files with
      | [] when not update || no_update -> Ok files
      | files when no_update ->
          Fmt.error
            "@[<v>No doc found for:@, %a@,@[Try with 'odig doc -u %a'@]@]"
            Fmt.(list Fpath.pp_quoted) files
            Fmt.(list Pkg.pp_name) pkgs
      | _ ->
          let index_title = None and index_intro = None and index_toc = None in
          let force = false and pkg_deps = true and tag_index = true in
          let* () =
            odoc_gen conf ~force ~index_title ~index_intro ~index_toc
              ~pkg_deps ~tag_index pkgs
          in
          Ok files
  in
  let does_not_exist = List.find_all (fun f -> not (exists f)) files in
  match does_not_exist with
  | [] when show_files ->
      Fmt.pr "@[<v>%a@]@." (Fmt.list Fpath.pp_unquoted) files; Ok 0
  | [] ->
      let rec loop exit = function
      | [] -> Ok exit
      | f :: fs ->
          let file_uri p = Fmt.str "file://%a" Fpath.pp_unquoted p in
          let u = file_uri f in
          match B0_web_browser.show ~background ~prefix:false browser u with
          | Error e -> Log.err (fun m -> m "%s" e); loop Exit.err_uri fs
          | Ok () -> loop exit fs
      in
      loop 0 files
  | fs ->
      Fmt.error "@[<v>No doc could be generated for:@,%a@]"
        (Fmt.list Fpath.pp_quoted) fs

let log_cmd conf no_pager format kind op_selector =
  Log.if_error ~use:Exit.some_error @@
  let don't = no_pager || format = `Trace_event in
  let* pager = B0_pager.find ~don't () in
  let* () = B0_pager.page_stdout pager in
  let log_file = Conf.b0_log_file conf in
  let* log = B0_memo_log.read log_file in
  B0_cli.Memo.Log.out Fmt.stdout format kind op_selector ~path:log_file log;
  Ok 0

let odoc_cmd
    conf _odoc pkg_names index_title index_intro index_toc force no_pkg_deps
    no_tag_index
  =
  let pkg_deps = not no_pkg_deps in
  let tag_index = not no_tag_index in
  Log.if_error ~use:Exit.no_such_name @@
  let* pkgs = find_pkgs conf pkg_names in
  Log.if_error' ~use:Exit.some_error @@
  let* () =
    odoc_gen conf
      ~force ~index_title ~index_intro ~index_toc ~pkg_deps ~tag_index pkgs
  in
  Ok 0

let pkg_cmd conf no_pager out_fmt pkg_names =
  Log.if_error ~use:Exit.no_such_name @@
  let* pkgs = find_pkgs conf pkg_names in
  Log.if_error' ~use:Exit.some_error @@
  let* pager = B0_pager.find ~don't:no_pager () in
  let* () = B0_pager.page_stdout pager in
  let pp_pkgs = match out_fmt with
  | `Short -> (fun ppf () -> (Fmt.list Pkg.pp_name) ppf pkgs)
  | `Normal ->
      let pp_pkg ppf (pkg, o) =
        Fmt.pf ppf "@[<h>%a %a %a@]"
          Pkg.pp_name pkg Pkg.pp_version (Opam.version o)
          (Fmt.st' [`Faint] Fpath.pp_quoted) (Pkg.path pkg)
      in
      let pkgs = Opam.query pkgs in
      (fun ppf () -> (Fmt.list pp_pkg) ppf pkgs)
  | `Long ->
      let pp_pkg ppf (pkg, i) =
        Fmt.pf ppf "@[<v>%a@,%a@]" Pkg.pp pkg Pkg_info.pp i
      in
      let pkgs = Pkg_info.query ~doc_dir:(Conf.doc_dir conf) pkgs in
      (fun ppf () -> (Fmt.list pp_pkg) ppf pkgs)
  in
  Fmt.pr "@[<v>%a@]@." pp_pkgs (); Ok 0

let show_cmd conf no_pager out_fmt show_empty field pkg_names =
  Log.if_error ~use:Exit.no_such_name @@
  let* pkgs = find_pkgs conf pkg_names in
  Log.if_error' ~use:Exit.some_error @@
  let* pager = B0_pager.find ~don't:no_pager () in
  let* () = B0_pager.page_stdout pager in
  let pp_field field out_fmt show_empty = match out_fmt with
  | `Short | `Normal ->
      (fun ppf (p, i) -> match Pkg_info.get field i with
        | [] -> if show_empty then Fmt.pf ppf "@," else ()
        | vs -> Fmt.pf ppf "%a@," Fmt.(list string) vs)
  | `Long ->
      (fun ppf (p, i) -> match Pkg_info.get field i with
        | [] when not show_empty -> ()
        | [] -> Fmt.pf ppf "@[<h>%a@]@," Pkg.pp_name p
        | vs ->
            let pp_val ppf v = Fmt.pf ppf "@[<h>%a %s@]" Pkg.pp_name p v in
            Fmt.pf ppf "%a@," Fmt.(list pp_val) vs)
  in
  let infos = Pkg_info.query ~doc_dir:(Conf.doc_dir conf) pkgs in
  let pp_field = pp_field field out_fmt show_empty in
  Fmt.pr "@[<v>%a@]@?" Fmt.(list ~sep:Fmt.nop pp_field) infos;
  Ok 0

let show_files_cmd conf no_pager pkg_names get_files =
  Log.if_error ~use:Exit.no_such_name @@
  let* pkgs = find_pkgs conf pkg_names in
  Log.if_error' ~use:Exit.some_error @@
  let* pager = B0_pager.find ~don't:no_pager () in
  let doc_dir = Conf.doc_dir conf in
  let doc_dirs = List.map (fun p -> p, (Doc_dir.of_pkg ~doc_dir p)) pkgs in
  let files = List.concat (List.map (fun (p, i) -> get_files i) doc_dirs) in
  let* () = B0_pager.page_files pager files in
  Ok 0


let theme_list_cmd conf out_fmt =
  match B0_odoc.Theme.of_dir (Conf.share_dir conf) with
  | [] -> 0
  | ts ->
      let pp_theme = function
      | `Short -> B0_odoc.Theme.pp_name
      | `Normal | `Long -> B0_odoc.Theme.pp
      in
      Fmt.pr "@[<v>%a@]@." (Fmt.list (pp_theme out_fmt)) ts; 0

let theme_get_cmd conf read_conf =
  Log.if_error ~level:Log.Error ~use:Exit.some_error @@
  let* name = match read_conf with
  | false -> Ok (Conf.odoc_theme conf)
  | true ->
      let* name = B0_odoc.Theme.get_user_preference () in
      Ok (Option.value ~default:B0_odoc.Theme.odig_default name)
  in
  Fmt.pr "%s@." name; Ok 0

let theme_set_cmd conf theme =
  let ts = B0_odoc.Theme.of_dir (Conf.share_dir conf) in
  let theme = match theme with None -> Conf.odoc_theme conf | Some t -> t in
  Log.if_error ~level:Log.Error ~use:Exit.no_such_name @@
  let* t = B0_odoc.Theme.find ~fallback:None theme ts in
  Log.if_error' ~use:Exit.some_error @@
  let* () = Odig_odoc.install_theme conf (Some t) in
  let name = Some (B0_odoc.Theme.name t) in
  let* () = B0_odoc.Theme.set_user_preference name in
  Ok 0

let theme_path_cmd conf theme =
  let ts = B0_odoc.Theme.of_dir (Conf.share_dir conf) in
  let theme = match theme with None -> Conf.odoc_theme conf | Some t -> t in
  Log.if_error ~level:Log.Error ~use:Exit.no_such_name @@
  let* t = B0_odoc.Theme.find ~fallback:None theme ts in
  Fmt.pr "%a@." Fpath.pp_unquoted (B0_odoc.Theme.path t); Ok 0

(* Command line interface *)

open Cmdliner

(* Arguments and commonalities *)

let exits =
  Cmd.Exit.info Exit.no_such_name
    ~doc:"a specified entity name cannot be found." ::
  Cmd.Exit.info Exit.err_uri ~doc:"an URI cannot be shown in a browser." ::
  Cmd.Exit.defaults

let format = B0_std_cli.output_format ()
let conf =
  let absent = "see below" in
  let path = B0_std_cli.fpath in
  let docs = Manpage.s_common_options in
  let docv = "PATH" in
  let doc dirname dir =
    Fmt.str
      "%s directory. If unspecified, $(b,\\$PREFIX)/%s with $(b,\\$PREFIX) \
       the parent directory of $(mname)'s install directory." dirname dir
  in
  let b0_cache_dir =
    let env = Cmd.Env.info Env.b0_cache_dir in
    let doc_none = "$(b,.cache) in odig cache directory" in
    B0_cli.Memo.cache_dir ~opts:["b0-cache-dir"] ~doc_none ~env ()
  in
  let b0_log_file =
    let env = Cmd.Env.info Env.b0_log_file in
    let doc_none = "$(b,.log) in odig cache directory" in
    B0_cli.Memo.log_file ~docs ~doc_none ~env ()
  in
  let cache_dir =
    let doc = doc "Cache" "var/cache/odig" in
    let env = Cmd.Env.info Env.cache_dir in
    Arg.(value & opt (some path) None &
         info ["cache-dir"] ~absent ~doc ~docs ~env ~docv)
  in
  let doc_dir =
    let doc = doc "Documentation" "doc" in
    let env = Cmd.Env.info Env.doc_dir in
    Arg.(value & opt (some path) None &
         info ["doc-dir"] ~absent ~doc ~docs ~env ~docv)
  in
  let lib_dir =
    let doc = doc "Library" "lib" in
    let env = Cmd.Env.info Env.lib_dir in
    Arg.(value & opt (some path) None &
         info ["lib-dir"] ~absent ~doc ~docs ~env ~docv)
  in
  let odoc_theme =
    let doc =
      "Theme to use for odoc documentation. If unspecified, the theme can be \
       specified in the file $(b,~/.config/odig/odoc-theme) or \
       $(b,odig.default) is used."
    in
    let env = Cmd.Env.info Env.odoc_theme in
    Arg.(value & opt (some string) None &
         info ["odoc-theme"] ~doc ~docs ~env ~docv:"THEME")
  in
  let share_dir =
    let doc = doc "Share" "share" in
    let env = Cmd.Env.info Env.share_dir in
    Arg.(value & opt (some path) None &
         info ["share-dir"] ~absent ~doc ~docs ~env ~docv)
  in
  let jobs = B0_cli.Memo.jobs ~docs ~env:(Cmd.Env.info "ODIG_JOBS") () in
  let color = B0_std_cli.color ~env:(Cmd.Env.info Env.color) () in
  let log_level = B0_std_cli.log_level ~env:(Cmd.Env.info Env.verbosity) () in
  let conf
      b0_cache_dir b0_log_file cache_dir doc_dir jobs lib_dir log_level
      odoc_theme share_dir color
    =
    Result.map_error (fun s -> `Msg s) @@
    Conf.setup_with_cli
      ~b0_cache_dir ~b0_log_file ~cache_dir ~doc_dir ~jobs ~lib_dir ~log_level
      ~odoc_theme ~share_dir ~color ()
  in
  Term.term_result @@
  Term.(const conf $ b0_cache_dir $ b0_log_file $ cache_dir $ doc_dir $ jobs $
        lib_dir $ log_level $ odoc_theme $ share_dir $ color)

let pkgs_pos1_nonempty, pkgs_pos, pkgs_pos1, pkgs_opt =
  let doc = "Package to consider (repeatable)." in
  let docv = "PKG" in
  Arg.(non_empty & pos_right 0 string [] & info [] ~doc ~docv),
  Arg.(value & pos_all string [] & info [] ~doc ~docv),
  Arg.(value & pos_right 0 string [] & info [] ~doc ~docv),
  Arg.(value & opt_all string [] & info ["p"; "pkg"] ~doc ~docv)

let background = B0_web_browser.background ()
let browser = B0_web_browser.browser ()
let no_pager = B0_pager.don't ()

let show_files_cmd ?cmd ~kind get_files =
  let cname = match cmd with None -> kind | Some cmd -> cmd in
  let doc = Fmt.str "Show package %s files" kind in
  let envs = B0_pager.Env.infos in
  let man =
    [ `S "DESCRIPTION";
      `P (Fmt.str "The $(tname) command shows package %s files. If \
                   invoked with $(b,--no-pager) and multiple files are output \
                   these are separated by a U+001C (file separator) control \
                   character." kind);
      `P "To output the file paths rather than their content use $(mname) \
          $(b,show)." ]
  in
  Cmd.v (Cmd.info cname ~doc ~envs ~exits ~man)
    Term.(const show_files_cmd $ conf $ no_pager $ pkgs_pos $ const get_files)

let subcmd ?(exits = exits) ?(envs = []) name ~doc ~descr term =
  let man = [`S Manpage.s_description; descr] in
  Cmd.v (Cmd.info name ~doc ~exits ~envs ~man) term

(* Commands *)

let browse_cmd =
  let doc = "Open package metadata URIs in your browser" in
  let man = [
    `S Manpage.s_description;
    `P "$(tname) command opens or reloads metadata URI fields of packages
        in a WWW browser." ]
  in
  let field =
    let field =
      [ "homepage", `Homepage; "issues", `Issues; "online-doc", `Online_doc; ]
    in
    let alts = Arg.doc_alts_enum field in
    let doc = Fmt.str "The URI field to show. $(docv) must be %s." alts in
    let action = Arg.enum field in
    Arg.(required & pos 0 (some action) None & info [] ~doc ~docv:"FIELD")
  in
  Cmd.v (Cmd.info "browse" ~doc ~exits ~man)
    Term.(const browse_cmd $ conf $ background $ browser $ field $
          pkgs_pos1_nonempty)

let cache_cmd =
  let doc = "Operate on the odig cache" in
  let man = [
    `S Manpage.s_description;
    `P "The $(tname) command operates on the odig cache."]
  in
  let clear_cmd =
    let doc = "Clear the cache" in
    let descr = `P "$(tname) clears the cache." in
    subcmd "clear" ~doc ~descr Term.(const cache_cmd $ conf $ const `Clear)
  in
  let path_cmd =
    let doc = "Show cache directory path" in
    let descr = `P "$(tname) outputs the path to the cache directory." in
    subcmd "path" ~doc ~descr Term.(const cache_cmd $ conf $ const `Path)
  in
  let trim_cmd =
    let doc = "Trim cache (does not affect generated docs)" in
    let descr = `P "$(mname) trims the cache without affecting generated \
                    documentation."
    in
    subcmd "trim" ~doc ~descr Term.(const cache_cmd $ conf $ const `Trim)
  in
  let subcmds = [clear_cmd; path_cmd; trim_cmd] in
  Cmd.group (Cmd.info "cache" ~doc ~exits ~man) subcmds

let changes_cmd =
  show_files_cmd ~cmd:"changes" ~kind:"change log" Doc_dir.changes_files

let conf_cmd =
  let doc = "Show odig configuration" in
  let man = [
    `S Manpage.s_description;
    `P "$(tname) outputs the odig configuration.";
    `P "$(mname) needs to know the path to the library directory, the
        path to the documentation directory, the path to the share
        directory and the path to the odig cache.";
    `P "Each can be specified on the command line or via an environment
        variable. If none of this is done they are determined relative
        to the binary's install directory. See the options $(b,--lib-dir),
        $(b,--doc-dir), $(b,--share-dir) and $(b,--cache-dir) for details."; ]
  in
  Cmd.v (Cmd.info "conf" ~doc ~exits ~man)
    Term.(const conf_cmd $ conf)

let doc_cmd =
  let doc = "Show odoc API documentation and manuals" in
  let man_xrefs = [ `Main; `Cmd "odoc" ] in
  let man = [
    `S Manpage.s_description;
    `P "$(tname) shows API documentation and manuals as generated
        by $(mname) $(b,odoc)."; ]
  in
  let update =
    let doc =
      "Make sure docs for the request are up-to-date. This happens \
       automatically if part of the request cannot be found, use \
       $(b,--no-update) to prevent this."
    in
    Arg.(value & flag & info ["u"; "update"] ~doc)
  in
  let no_update =
    let doc = "Never try to update the docs. Takes over $(b,--update)." in
    Arg.(value & flag & info ["n"; "no-update"] ~doc)
  in
  let show_files =
    let doc =
      "Output files on stdout one by line, rather than trying to open them \
       in a broken way."
    in
    Arg.(value & flag & info ["f"; "show-files"] ~doc)
  in
  Cmd.v (Cmd.info "doc" ~doc ~exits ~man ~man_xrefs)
    Term.(const doc_cmd $ conf $ background $ browser $ pkgs_pos $ update $
          no_update $ show_files)

let license_cmd = show_files_cmd ~kind:"license" Doc_dir.license_files

let odoc_cmd =
  let doc = "Generate odoc API documentation and manuals" in
  let man = [
    `S Manpage.s_description;
    `P "$(tname) generates the odoc API documentation and manual of packages.";
    `P "See the packaging conventions in $(mname) $(b,doc) $(mname) for
        generation details."; ]
  in
  let odoc = Term.const "odoc"
(* let doc = "The odoc command to use." in
    let env = Cmd.Env.info "ODIG_ODOC" in
    Arg.(value & opt string "odoc" & info ["odoc"] ~env ~docv:"CMD" ~doc) *)
  in
  let force = Term.const false
    (* let doc = "Force generation even if files are up-to-date." in
    Arg.(value & flag & info ["f"; "force"] ~doc) *)
  in
  let index_title =
    let doc = "$(docv) is the title of the package list page." in
    let docv = "TITLE" in
    Arg.(value & opt (some string) None & info ["index-title"] ~docv ~doc)
  in
  let index_intro =
    let doc = "$(docv) is the .mld file to use to define the introduction
               text on the package list page."
    in
    let some_path = Arg.some B0_std_cli.fpath in
    Arg.(value & opt some_path None & info ["index-intro"] ~docv:"MLDFILE" ~doc)
  in
  let index_toc =
    let doc = "$(docv) is the .mld file to use to define the contents of the
               table of contents on the package list page."
    in
    let some_path = Arg.some B0_std_cli.fpath in
    Arg.(value & opt some_path None & info ["index-toc"] ~docv:"MLDFILE" ~doc)
  in
  let no_pkg_deps =
    let doc = "Restrict documentation generation to the packages mentioned \
               on the command line, their dependencies are not automatically \
               included in the result. Note that this may lead to broken \
               links in the documentation set."
    in
    Arg.(value & flag & info ["no-pkg-deps"] ~doc)
  in
  let no_tag_index =
    let doc = "Do not generate the tag index on the package list page." in
    Arg.(value & flag & info ["no-tag-index"] ~doc)
  in
  Cmd.v (Cmd.info "odoc" ~doc ~exits ~man)
    Term.(const odoc_cmd $ conf $ odoc $ pkgs_pos $ index_title $ index_intro $
          index_toc $ force $ no_pkg_deps $ no_tag_index)

let odoc_theme_cmd =
  let theme =
    let doc = "Theme name." and docv = "THEME" in
    let absent = "value of $(b,odig odoc-theme get)" in
    Arg.(value & pos 0 (some string) None & info [] ~absent ~doc ~docv)
  in
  let get_cmd =
    let doc = "Get the theme used on documentation generation" in
    let descr = `Blocks [
        `P "$(mname) shows the theme used on documentation generation.";
        `P "This is either, in order, the value of the $(b,--odoc-theme) \
            option, the value of the $(b,ODIG_ODOC_THEME) environment \
            variable, the stripped contents of the \
            $(b,~/.config/odig/odoc-theme) file or $(b,odig.default)";
        `P "Use $(b,--config) to get the value from \
            the configuration file; $(b,odig.default) is returned if there is
            not such file."; ]
    in
    let read_conf =
      let doc =
        "Show the value written in $(b,~/.config/odig/odoc-theme) \
         or $(b,odig.default) if there is no such file."
      in
      Arg.(value & flag & info ["conf"] ~doc)
    in
    subcmd "get" ~doc ~descr Term.(const theme_get_cmd $ conf $ read_conf)
  in
  let list_term = Term.(const theme_list_cmd $ conf $ format) in
  let list_cmd =
    let doc = "List available themes (default command)" in
    let descr = `P "$(tname) lists available themes." in
    subcmd "list" ~doc ~descr list_term
  in
  let path_cmd =
    let doc = "Show theme directory" in
    let descr = `P "$(tname) shows the directory of $(i,THEME)"
    in
    subcmd "path" ~doc ~descr Term.(const theme_path_cmd $ conf $ theme)
  in
  let set_cmd =
    let doc = "Set theme used on documentation generation" in
    let descr =
      `P "$(tname) changes the theme used on documentation generation
         to $(i,THEME) and persists the choice in \
          $(b,~/.config/odig/odoc-theme).";
    in
    subcmd "set" ~doc ~descr Term.(const theme_set_cmd $ conf $ theme)
  in
  let subcmds = [get_cmd; list_cmd; path_cmd; set_cmd] in
  let doc = "Manage themes for odoc API and manual documentation." in
  let man = [
    `S Manpage.s_description;
    `P "$(tname) lists and sets the theme used by odoc documentation. The \
        default command is $(tname) $(b,list).";
    `P "See the packaging conventions in $(b,odig doc) $(mname) for the \
        theme install structure.";
    `S Manpage.s_options;
    `S B0_std_cli.s_output_format_options;
  ]
  in
  Cmd.group (Cmd.info "odoc-theme" ~doc ~exits ~man)
    ~default:list_term subcmds

let log_cmd =
  let doc = "Show odoc build log" in
  let envs = B0_pager.Env.infos in
  let man = [
    `S Manpage.s_description;
    `P "The $(tname) command shows odoc build operations.";
    `S Manpage.s_options;
    `S B0_std_cli.s_output_format_options;
    `S B0_cli.Op.s_selection_options;
    `Blocks B0_cli.Op.query_man ]
  in
  Cmd.v (Cmd.info "log" ~doc ~exits ~envs ~man)
    Term.(const log_cmd $ conf $ no_pager $
          B0_cli.Memo.Log.out_format_cli () $ format $ B0_cli.Op.query_cli ())

let pkg_term = Term.(const pkg_cmd $ conf $ no_pager $ format $ pkgs_pos)
let pkg_cmd =
  let doc = "Show packages (default command)" in
  let envs = B0_pager.Env.infos in
  let man = [
    `S Manpage.s_description;
    `P "The $(tname) command shows packages known to odig. If no packages
        are specified, all packages are shown.";
    `P "See the packaging conventions in $(b,odig doc) $(mname) for the package
        install structure.";
    `S Manpage.s_commands;
    `S Manpage.s_options;
    `S B0_std_cli.s_output_format_options; ]
  in
  Cmd.v (Cmd.info "pkg" ~doc ~envs ~exits ~man) pkg_term

let readme_cmd = show_files_cmd ~kind:"readme" Doc_dir.readme_files
let show_cmd =
  let doc = "Show package metadata" in
  let envs = B0_pager.Env.infos in
  let man = [
    `S Manpage.s_description;
    `P "$(tname) outputs package metadata. If no packages
        are specified, information for all packages is shown.";
    `P "Outputs a single non-empty value per line; to output empty
        value use the $(b,--show-empty) option.";
    `P "To preceed values by the name of the package they apply to, use
        the $(b,--long) option.";
    `S Manpage.s_options;
    `S B0_std_cli.s_output_format_options; ]
  in
  let field =
    let field = Odig_support.Pkg_info.field_names in
    let alts = Arg.doc_alts_enum field in
    let doc = Fmt.str "The field to show. $(docv) must be %s." alts in
    let action = Arg.enum field in
    Arg.(required & pos 0 (some action) None & info [] ~doc ~docv:"FIELD")
  in
  let show_empty =
    let doc = "Show empty fields." in
    Arg.(value & flag & info ["e"; "show-empty"] ~doc)
  in
  Cmd.v (Cmd.info "show" ~doc ~envs ~exits ~man)
    Term.(const show_cmd $ conf $ no_pager $ format $ show_empty $ field $
          pkgs_pos1)

let subs =
  [ browse_cmd; cache_cmd; changes_cmd; conf_cmd; doc_cmd; license_cmd;
    log_cmd; odoc_cmd; odoc_theme_cmd; pkg_cmd; readme_cmd; show_cmd; ]

let odig =
  let doc = "Lookup documentation of installed OCaml packages" in
  let man = [
    `S Manpage.s_description;
    `P "$(mname) looks up documentation of installed OCaml packages. It shows \
        package metadata, readmes, change logs, licenses, cross-referenced \
        $(b,odoc) API documentation and manuals.";
    `P "See $(b,odig doc) $(mname) for a tutorial and more details."; `Noblank;
    `P "See $(mname) $(b,conf --help) for information about $(mname) \
        configuration.";
    `S Manpage.s_options;
    `S B0_std_cli.s_output_format_options;
    `S Manpage.s_see_also;
    `P "Consult $(b,odig doc odig) for a tutorial, packaging conventions and
         more details.";
    `S Manpage.s_bugs;
    `P "Report them, see $(i,%%PKG_HOMEPAGE%%) for contact information." ];
  in
  Cmd.group (Cmd.info "odig" ~version:"%%VERSION%%" ~doc ~exits ~man)
    ~default:pkg_term subs

let main () =
  exit @@ Log.time (fun _ m -> m "total time") @@ fun () ->
  Cmd.eval' odig

let () = main ()
