(*---------------------------------------------------------------------------
   Copyright 2013 Daniel C. Bünzli. All rights reserved.
   Distributed under the BSD3 license, see license at the end of the file.
   %%NAME%% release %%VERSION%%
  ---------------------------------------------------------------------------*)

let str = Format.sprintf
let exec = Filename.basename Sys.executable_name

(* Pretty printers *) 

let pp = Format.fprintf
let pp_str = Format.pp_print_string 
let rec pp_list ?(pp_sep = Format.pp_print_cut) pp_v ppf = function 
| [] -> ()
| v :: vs -> 
    pp_v ppf v; if vs <> [] then (pp_sep ppf (); pp_list ~pp_sep pp_v ppf vs)

let pp_base_type ppf b = pp_str ppf (Capi.base_type_to_string b)
let pp_ocaml_type_def ppf = function 
| `Unknown _ -> pp ppf "unknown"
| `Ok def -> 
    let name = def.Oapi.type_name in
    let odef = match def.Oapi.type_def with 
    | `Builtin -> name | `Alias a | `Abstract a -> str "type %s = %s" name a
    in  
    let ctypes = match def.Oapi.type_ctypes with 
    | `Builtin c | `Builtin_wrap_in (c, _) | `View (c, _, _, _) 
    | `Def (c, _) -> c
    in
    pp ppf "%s, %s" odef ctypes

let pp_base_type_def ppf = function 
| `Def d -> pp ppf "typedef %s" d | `Builtin -> ()

let rec pp_type ?(def = true) api ppf = function 
| `Base b as t when def -> 
    let odef = Oapi.type_def api t in
    pp ppf "@[%a (%a) %a@]" 
      pp_base_type b
      pp_ocaml_type_def odef
      pp_base_type_def (Capi.base_type_def api b)
| t ->
    if not def then pp ppf "@[%s@]" (Capi.type_to_string t) else 
    let odef = Oapi.type_def api t in 
    pp ppf "@[%s (%a)@]" (Capi.type_to_string t) pp_ocaml_type_def odef 

let pp_arg_len ppf = function
| `Size i -> pp ppf "%d" i 
| `Arg a -> pp ppf "arg:%s" a
| `Csize a -> pp ppf "csize:%s" a
| `Other a -> pp ppf "unparsed:%s" a

let pp_fun_def  ppf = function 
| `Derived _ -> pp ppf "derived"
| `Unbound _ -> pp ppf "unbound" 
| `Manual _ -> pp ppf "manual"
| `Unknown -> pp ppf "unknown"

let pp_fun api ppf f = 
  let cname, (cargs, cret) = f.Oapi.fun_c in
  let def = false in
  let pp_sep ppf () = pp ppf " -> " in
  let pp_carg ppf a = match a.Capi.arg_len with 
  | None -> pp_type ~def api ppf a.Capi.arg_type 
  | Some l -> pp ppf "%a [%a]" (pp_type ~def api) a.Capi.arg_type pp_arg_len l
  in
  pp ppf "@[<h>%a %s (%s) : %a -> %a@]" 
    pp_fun_def f.Oapi.fun_def
    cname f.Oapi.fun_name
    (pp_list ~pp_sep pp_carg) cargs (pp_type ~def api) cret

let pp_enum api ppf e =
  let v = match e.Oapi.enum_value with 
  | `GLenum v -> str "@[GLenum 0x%04X@]" v
  | `GLuint v -> str "@[GLuint 0x%04lX@]" v
  | `GLuint64 v -> str "@[GLuint64 0x%04LX@]" v
  in
  pp ppf "@[<h>%s %s (%s)@]" v e.Oapi.enum_c_name e.Oapi.enum_name

let api_query ppf api q =
  let log = Format.err_formatter in
  let pp_defs pp_v defs = pp ppf "@[<v>%a@,@]" (pp_list (pp_v api)) defs in
  match q with 
  | `Types -> pp_defs pp_type (Capi.types api); `Ok
  | `Funs -> pp_defs pp_fun (Oapi.funs api); `Ok
  | `Enums -> pp_defs pp_enum (Oapi.enums api); `Ok
  | `Mli -> pp ppf "%a" (Gen.pp_api_mli ~log) api; `Ok
  | `Ml -> pp ppf "%a" (Gen.pp_api_ml ~log) api; `Ok
  | `List -> assert false

let list_apis reg =
  let add_features api features acc = 
    let api = match api with "gles2" | "gles1" -> "gles" | _ -> api in
    let add_feature acc feature = 
      (str "%s%d.%d" api 
         (fst feature.Glreg.f_number) (snd feature.Glreg.f_number)) :: acc
    in
    List.fold_left add_feature acc features
  in
  let features = Hashtbl.fold add_features reg.Glreg.features [] in 
  let add_extension ext _ acc = ext :: acc in
  let exts = Hashtbl.fold add_extension reg.Glreg.extensions [] in 
  List.sort compare (List.rev_append exts features)

let process inf api_id profile query = 
  try
    let inf = match inf with None -> "support/gl.xml" | Some inf -> inf in
    let ic = if inf = "-" then stdin else open_in inf in
    let d = Glreg.decoder (`Channel ic) in
    try match Glreg.decode d with
    | `Ok reg -> 
        close_in ic;
        begin match query with 
        | `List -> 
            List.iter (pp Format.std_formatter "%s@\n") (list_apis reg); 
            exit 0
        | query -> 
            begin match Capi.create reg api_id profile with 
            | `Error e -> Printf.eprintf "%s: %s\n%!" exec e; `Error
            | `Ok api -> api_query Format.std_formatter api query
            end
        end
    | `Error e -> 
        let (l0, c0), (l1, c1) = Glreg.decoded_range d in
        Printf.eprintf "%s:%d.%d-%d.%d: %s\n%!" inf l0 c0 l1 c1 e; `Error
    with e -> close_in ic; raise e
  with Sys_error e -> Printf.eprintf "%s\n%!" e; `Error 

let main () =
  let usage = str 
      "Usage: %s [OPTION]... [INFILE]\n\
       \ Query an OpenGL API from a registry file.\n\
       \ INFILE defaults to support/gl.xml\n\
       Options:" exec 
  in
  let inf = ref None in 
  let set_inf f = 
    if !inf = None then inf := Some f else
    raise (Arg.Bad "only one registry file can be specified")
  in
  let query = ref `Funs in
  let set_query v () = query := v in
  let api_id = ref (`Gl (4, 4)) in
  let set_api_id s = api_id := Capi.id_of_string s in
  let profile = ref "core" in
  let options = [
    "-api", Arg.String set_api_id, 
    "<glX.Y|glesX.Y> API to query, see -list (defaults to `gl4.4')";
    "-list", Arg.Unit (set_query `List), 
    " list the available APIs for the -api option";
    "-profile", Arg.Set_string profile, 
    "<profile> API profile (defaults to `core')";
    "-types", Arg.Unit (set_query `Types), 
    " print API C types"; 
    "-funs", Arg.Unit (set_query `Funs), 
    " print API functions and their signature"; 
    "-enums", Arg.Unit (set_query `Enums), 
    " print API enums and their value"; 
    "-ml", Arg.Unit (set_query `Ml), 
    " print ml file for binding the API"; 
    "-mli", Arg.Unit (set_query `Mli), 
    " print mli file for binding the API"; ]
  in
  Arg.parse (Arg.align options) set_inf usage; 
  match process !inf !api_id !profile !query with 
  | `Ok -> exit 0 | `Error -> exit 1
  
let () = main ()

(*---------------------------------------------------------------------------
   Copyright 2013 Daniel C. Bünzli.
   All rights reserved.

   Redistribution and use in source and binary forms, with or without
   modification, are permitted provided that the following conditions
   are met:
     
   1. Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.

   2. Redistributions in binary form must reproduce the above
      copyright notice, this list of conditions and the following
      disclaimer in the documentation and/or other materials provided
      with the distribution.

   3. Neither the name of Daniel C. Bünzli nor the names of
      contributors may be used to endorse or promote products derived
      from this software without specific prior written permission.

   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
   "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
   LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
   A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
   OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
   SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
   LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
   DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
   THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
   (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
   OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
  ---------------------------------------------------------------------------*)
