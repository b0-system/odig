(*---------------------------------------------------------------------------
   Copyright 2013 Daniel C. Bünzli. All rights reserved.
   Distributed under the BSD3 license, see license at the end of the file.
   %%NAME%% release %%VERSION%%
  ---------------------------------------------------------------------------*)

let str = Printf.sprintf 
let pp = Format.fprintf 

(* Error strings *)

let err_ext e = str "unknown extension (%s)" e
let err_no_version api (maj, min) = 
  let api = match api with 
  | "gl" -> "OpenGL" | "gles1" | "gles2" -> "OpenGL ES" | api -> api 
  in
  str "Unknown version %s %d.%d" api maj min 

let err_fun_defs f = str "Unsupported: function `%s' has multiple definitions" f
let err_fun_undef f = str "No definition for function `%s'" f

let err_base_type b = str "Unsupported: base type `%s'" b
let err_base_type_undef b = str "No definition for base type `%s'" b
let err_type t = str "Unsupported: type `%s'" t

let err_enum_defs e = str "Unsupported: enum `%s' has multiple definitions" e
let err_enum_undef e = str "No definition for enum `%s'" e
let err_enum_parse e v t = str "Could not parse enum `%s' as `%s' (`%s')" e t v
let err_enum_type t e = str "Unsupported: enum type `%s' for `%s'" t e

(* String maps and sets *)

module Smap = Map.Make(String)
module Sset = struct 
  include Set.Make(String)
  let map f s = fold (fun e acc -> add (f e) acc) s empty
end

(* API identifiers *)

type version = int * int
type id = [ `Gl of version | `Gles of version | `Ext of string ]

let id_of_string s = 
  let is_digit c = '0' <= c && c <= '9'  in
  let int_of_digit c = Char.code c - Char.code '0' in
  match String.length s with 
  | 3 (* glX *) -> 
      if s.[0] = 'g' && s.[1] = 'l' && is_digit s.[2] 
      then `Gl (int_of_digit s.[2], 0)
      else `Ext s
  | 5 (* glX.X or glesX *) -> 
      if s.[0] = 'g' && s.[1] = 'l' && 
         is_digit s.[2] && s.[3] = '.' && is_digit s.[4] 
      then `Gl (int_of_digit s.[2], int_of_digit s.[4]) else
      if s.[0] = 'g' && s.[1] = 'l' && s.[2] = 'e' && s.[3] = 's' &&
         is_digit s.[4] 
      then `Gles (int_of_digit s.[4], 0)
      else `Ext s
  | 7 (* glesX.X *) -> 
      if s.[0] = 'g' && s.[1] = 'l' && s.[2] = 'e' && s.[3] = 's' &&
         is_digit s.[4] && s.[5] = '.' && is_digit s.[6] 
      then `Gles (int_of_digit s.[4], int_of_digit s.[6])
      else `Ext s
  | _ -> `Ext s

(* Get C function and enum names for an API in the registry *) 

let with_interface_names op (funs, enums as acc) i = match i.Glreg.i_type with
| `Command -> (op i.Glreg.i_name funs, enums)
| `Enum -> (funs, op i.Glreg.i_name enums)
| `Type (* useless in current registry *) -> acc 
    
let names_api_profile r ~api profile version = 
  let features = try Hashtbl.find r.Glreg.features api with 
  | Not_found -> assert false 
  in
  if not (List.exists (fun f -> f.Glreg.f_number = version) features)
  then `Error (err_no_version api version) else 
  (* Get all features smaller or equal to this version and sort them *)
  let keep_feature f = f.Glreg.f_number <= version in
  let sort_feature f f' = compare f.Glreg.f_number f'.Glreg.f_number in
  let features = List.sort sort_feature (List.filter keep_feature features) in
  let keep_interface i =
    let keep_for_api = match i.Glreg.i_api with 
    | None -> true | Some api -> api = api 
    in
    let keep_for_profile = match i.Glreg.i_profile with 
    | None -> true | Some p -> p = profile 
    in
    keep_for_api && keep_for_profile
  in
  let add_feature acc f = 
    let adds = List.filter keep_interface f.Glreg.f_require in 
    let rems = List.filter keep_interface f.Glreg.f_remove in 
    let acc = List.fold_left (with_interface_names Sset.add) acc adds in 
    let acc = List.fold_left (with_interface_names Sset.remove) acc rems in
    acc
  in
  `Ok (List.fold_left add_feature (Sset.empty, Sset.empty) features)

let names_ext r ext profile = 
  try
    (* doc says no removes in exts, altough this is allowed by the schema *)
    let x = Hashtbl.find r.Glreg.extensions ext in
    let acc = (Sset.empty, Sset.empty) in
    `Ok (List.fold_left (with_interface_names Sset.add) acc x.Glreg.x_require)
  with Not_found -> `Error (err_ext ext)

let registry_api r id = match id with 
| `Gl _ -> "gl" 
| `Gles (1, _) -> "gles1"
| `Gles _ ->  "gles2" 
| `Ext e -> failwith "Extension support is TODO"

let names r id profile = 
  let api = registry_api r id in
  match id with
  | `Gl version -> names_api_profile r ~api profile version
  | `Gles (1, _ as version) -> names_api_profile r ~api profile version
  | `Gles version -> names_api_profile r ~api profile version
  | `Ext ext -> names_ext r ext profile

(* Apis *) 

type t = 
  { registry : Glreg.t; 
    registry_api : string;
    id : id; 
    profile : string option;
    fun_names : Sset.t;                  (* C functions names in the API. *) 
    enum_names : Sset.t;                (* C enumerants names in the API. *) }
  
let create registry id profile = 
  let registry_api = registry_api registry id in
  match names registry id profile with 
  | `Error _ as e -> e
  | `Ok (fun_names, enum_names) -> 
      let profile = match id with 
      | `Ext _ | `Gles _ -> None | _ -> Some profile 
      in
      `Ok { registry; registry_api; id; profile; fun_names; enum_names; }
        
let id api = api.id 
let profile api = api.profile 
                    
let lookup_fun registry f = 
  try match Hashtbl.find registry.Glreg.commands f with
  | [cmd] -> cmd
  | _ -> failwith (err_fun_defs f)
  with Not_found -> failwith (err_fun_undef f)

(* C types *) 

type base_type = 
  [ `GLbitfield | `GLboolean | `GLbyte | `GLchar | `GLclampx | `GLdouble 
  | `GLenum | `GLfixed | `GLfloat | `GLint | `GLint64 | `GLintptr | `GLshort 
  | `GLsizei | `GLsizeiptr | `GLsync | `GLubyte | `GLuint | `GLuint64 
  | `GLushort | `GLDEBUGPROC | `Void | `Void_or_index ]

let base_type_to_string = function 
| `GLbitfield -> "GLbitfield" | `GLboolean -> "GLboolean" | `GLbyte -> "GLbyte"
| `GLchar -> "GLchar" | `GLclampx -> "GLclampx" | `GLdouble -> "GLdouble" 
| `GLenum -> "GLenum" | `GLfixed -> "GLfixed" | `GLfloat -> "GLfloat" 
| `GLint -> "GLint" | `GLint64 -> "GLint64" | `GLintptr -> "GLintptr" 
| `GLshort -> "GLshort" | `GLsizei -> "GLsizei" | `GLsizeiptr -> "GLsizeiptr" 
| `GLsync -> "GLsync" | `GLubyte -> "GLubyte" | `GLuint -> "GLuint" 
| `GLuint64 -> "GLuint64" | `GLushort -> "GLushort" 
| `GLDEBUGPROC -> "GLDEBUGPROC" | `Void -> "void" 
| `Void_or_index -> "void_or_index"

let base_type_of_string = function 
| "GLbitfield" -> `GLbitfield | "GLboolean" -> `GLboolean | "GLbyte" -> `GLbyte
| "GLchar" -> `GLchar | "GLclampx" -> `GLclampx | "GLdouble" -> `GLdouble 
| "GLenum" -> `GLenum | "GLfixed" -> `GLfixed | "GLfloat" -> `GLfloat 
| "GLint" -> `GLint | "GLint64" -> `GLint64 | "GLintptr" -> `GLintptr 
| "GLshort" -> `GLshort | "GLsizei" -> `GLsizei | "GLsizeiptr" -> `GLsizeiptr 
| "GLsync" -> `GLsync | "GLubyte" -> `GLubyte | "GLuint" -> `GLuint 
| "GLuint64" -> `GLuint64 | "GLushort" -> `GLushort 
| "GLDEBUGPROC" -> `GLDEBUGPROC | "void" -> `Void 
| "void_or_index" -> `Void_or_index
| b -> failwith (err_base_type b)

let base_type_def api base = 
  let b = base_type_to_string base in 
  let defs = try Hashtbl.find api.registry.Glreg.types b with Not_found -> [] in
  let match_api t = t.Glreg.t_api = Some api.registry_api in
  match try Some (List.find match_api defs) with Not_found -> None with 
  | Some d -> `Def d.Glreg.t_def
  | None -> 
      let no_api t = t.Glreg.t_api = None in 
      match try Some (List.find no_api defs) with Not_found -> None with 
      | Some d -> `Def d.Glreg.t_def
      | None -> 
          match base with 
          | `Void -> `Builtin
          | _ -> failwith (err_base_type_undef b)

type typ = 
  [ `Base of base_type 
  | `Ptr of typ
  | `Const of typ 
  | `Nullable of typ ]

let type_to_string t = 
  let rec loop acc = function 
  | `Base b -> acc ^ (base_type_to_string b)
  | `Ptr t -> (loop acc t) ^ " *"
  | `Const t -> "const " ^ (loop acc t)
  | `Nullable t -> "nullable " ^ (loop acc t)
  in
  loop "" t 

let typ nullable t = 
  let const, typ = (* extract a possible const *)
    if String.length t <= 6 then `None, t else 
    match String.sub t 0 6 with
    | "const " -> `Const, String.sub t 6 (String.length t - 6) 
    | _ -> `None, t
  in
  let ptr, base =  (* extract possible pointers. *)    
    try 
      let star = String.index typ '*' in
      let base = String.trim (String.sub typ 0 star) in
      match String.sub typ star (String.length typ - star) with
      | "*" -> `Ptr, base
      | "**" -> `Ptr_ptr, base
      | "*const*" -> `Ptr_const_ptr, base
      | _ -> failwith (err_type t)
    with Not_found -> `None, typ
  in
  let base = base_type_of_string base in
  let t = match const, ptr with 
  | `None, `None -> `Base base
  | `None, `Ptr -> `Ptr (`Base base)
  | `None, `Ptr_ptr -> `Ptr (`Ptr (`Base base))
  | `Const, `Ptr -> `Const (`Ptr (`Base base))
  | `Const, `Ptr_const_ptr -> `Const (`Ptr (`Const (`Ptr (`Base base))))
  | _ -> failwith (err_type t)
  in
  if nullable then `Nullable t else t

let types api =
  let fun_types api f = 
    let cmd = lookup_fun api.registry f in
    let add_param acc (_, t) = Glreg.((t.p_nullable, t.p_type) :: acc) in
    let params = List.fold_left add_param [] cmd.Glreg.c_params in
    let params = if params = [] then [(false, "void")] else params in
    let ret = Glreg.(cmd.c_ret.p_nullable, cmd.c_ret.p_type) in
    List.rev (ret :: params)
  in
  let add_type acc t = if List.mem t acc then acc else t :: acc in
  let add_fun_types f acc = List.fold_left add_type acc (fun_types api f) in
  let types = List.sort compare (Sset.fold add_fun_types api.fun_names []) in
  List.map (fun (nullable, t) -> typ nullable t) types

(* C functions *) 

type arg_len = 
  [ `Arg of string | `Size of int | `Csize of string | `Other of string]

type arg = 
  { arg_name : string; 
    arg_type : typ; 
    arg_group : string option;
    arg_len : arg_len option }

type func = string * (arg list * typ) 

let void_arg = 
  { arg_name = ""; arg_type = `Base `Void; arg_group = None; arg_len = None }

let parse_arg_len = function 
| None -> None
| Some s -> 
    try Some (`Size (int_of_string s)) with (* try with an integer *) 
    | Failure _ -> 
        try
          let lpar = String.index s '(' in (* COMPSIZE(...) *)
          let rpar = String.index s ')' in 
          Some (`Csize (String.sub s (lpar + 1) (rpar - lpar - 1)))
        with Not_found -> 
          try 
            (* sometimes we have arg*{2,3,4} *)
            let _ = String.index s '*' in
            Some (`Other s)
          with 
          | Not_found -> Some (`Arg s)

let funs api = 
  let open Glreg in (* only for record field access. *) 
  let func f = 
    let add_arg acc (arg_name, param) = 
      let arg_type = typ param.p_nullable param.p_type in 
      let arg_group = param.p_group in
      let arg_len = parse_arg_len (param.p_len) in
      { arg_name; arg_type; arg_group; arg_len } :: acc
    in
    let cmd = lookup_fun api.registry f in
    let args = List.fold_left add_arg [] cmd.c_params in
    let args = if args = [] then [ void_arg ] else args in
    let ret = typ cmd.c_ret.p_nullable cmd.c_ret.p_type in
    f, (List.rev args, ret)
  in
  List.map func (Sset.elements api.fun_names)

(* C enumerations *) 

type enum_value = [ `GLenum of int | `GLuint64 of int64 | `GLuint of int32]
type enum = string * enum_value

let enums api = 
  let enum e =
    let e_def = try begin match Hashtbl.find api.registry.Glreg.enums e with
    | [e] -> e
    | _ -> failwith (err_enum_defs e)
    end with Not_found -> failwith (err_enum_undef e)
    in
    let get f v t = try f v with Failure _ -> failwith (err_enum_parse e t v) in
    let v = e_def.Glreg.e_value in
    let v = match e_def.Glreg.e_type with 
    | None -> `GLenum (get int_of_string v "<unspecified>")
    | Some ("ull" as t) -> `GLuint64 (get Int64.of_string v t)
    | Some ("u" as t) -> `GLuint (get Int32.of_string v t)
    | Some t -> failwith (err_enum_type t e)
    in
    e, v
  in
  List.map enum (Sset.elements api.enum_names)

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
