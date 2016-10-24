open Ocamlbuild_plugin

let strf = Printf.sprintf

(* Handle byte/native specific Odig_ocamltop module implementation. *)

let cp = if Sys.win32 then "copy" else "cp"

let cp_odig_ocamltop dir ext =
  let cmi = "%odig_ocamltop.cmi" in (* make sure it is built and seen *)
  let src = strf "%%%s/odig_ocamltop.%s" dir ext in
  let dst = strf "%%odig_ocamltop.%s" ext in
  rule (strf "cp %s to %s" src dst)
    ~prod:dst
    ~deps:[cmi; src]
    begin fun env _build ->
      (* FIXME Windows *)
      Cmd (S [ A cp; A (env src); A (env dst)])
    end

let () =
  dispatch begin function
  | After_rules ->
      cp_odig_ocamltop "byte" "cmo";
      cp_odig_ocamltop "native" "cmx";
      cp_odig_ocamltop "native" "o"
  | _ -> ()
  end
