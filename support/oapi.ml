(*---------------------------------------------------------------------------
   Copyright (c) 2013 Daniel C. Bünzli. All rights reserved.
   Distributed under the BSD3 license, see license at the end of the file.
   %%NAME%% release %%VERSION%%
  ---------------------------------------------------------------------------*)

let str = Printf.sprintf 
let pp = Format.fprintf 

(* Error string *)

let err_odd_fname f = str "Odd function name for OpenGL: `%s'" f
let err_odd_ename e = str "Odd enumerant name for OpenGL: `%s'" e
let err_no_type_def t = str "No OCaml type definition for %s" t

(* String maps and sets *)

module Smap = Map.Make(String)
module Sset = struct 
  include Set.Make(String)
  let map f s = fold (fun e acc -> add (f e) acc) s empty
end

(* API *) 

type t = Capi.t

let doc_synopsis api = match Capi.id api with 
| `Gl (maj, 0) -> str "OpenGL %d" maj
| `Gl (maj, _) -> str "OpenGL %d.x" maj
| `Gles (maj, 0) -> str "OpenGL ES %d" maj
| `Gles (maj, _) -> str "OpenGL ES %d.x" maj
| `Ext e -> e

let doc_synopsis_long api = 
  let mins x y = if y = 0 then str "%d" x else str "%d.0 to %d.%d" x x y in
  match Capi.id api with 
  | `Gl (3, 2) -> str "OpenGL 3.2" 
  | `Gl (3, 3) -> str "OpenGL 3.2 and 3.3" 
  | `Gl (maj, min) -> str "OpenGL %s" (mins maj min)
  | `Gles (maj, min) -> str "OpenGL ES %s" (mins maj min)
  | `Ext e -> e

(* OCaml identifiers
   add '_' to keywords, prefix with '_' if not lowercase start *)
let identifier = function
| "and" | "as" | "assert" | "asr" | "begin" | "class"
| "constraint" | "do" | "done" | "downto" | "else" 
| "end"| "exception" | "external" | "false" | "for" | "fun" | "function"
| "functor" | "if" | "in" | "include" | "inherit" | "initializer"
| "land" | "lazy" | "let" | "lor" | "lsl" | "lsr" | "lxor"
| "match" | "method" | "mod" | "module" | "mutable" | "new"
| "object" | "of" | "open" | "or" | "private" | "rec" | "sig"
| "struct" | "then" | "to" | "true" | "try" | "type" | "val"
| "virtual" | "when" | "while" | "with" as id -> id ^ "_" 
| name -> if 'a' <= name.[0] && name.[0] <= 'z' then name else "_" ^ name

(* Modules *) 

let module_lib api = match (Capi.id api) with
| `Gles (m, _) -> str "Tgles%d" m 
| `Gl (m, _) -> str "Tgl%d" m
| `Ext e -> str "T%s" (String.lowercase e)

let module_bind api = match (Capi.id api) with
| `Gles _ | `Gl _ -> "Gl"
| `Ext e -> let m = String.lowercase e in m.[0] <- Char.uppercase m.[0]; m

(* Types *) 

type ctypes = 
  [ `Builtin of string 
  | `View of string * string * string * string
  | `Builtin_wrap_in of string * (Format.formatter -> string -> unit)
  | `Def of string * string ]

type typ = 
  { type_name : string; 
    type_def : [ `Alias of string | `Abstract of string | `Builtin ];
    type_ctypes : ctypes;
    type_doc : string option; }

let bool = 
  { type_name = "bool"; 
    type_def = `Builtin;
    type_ctypes = `View ("bool",
                         "(fun u -> Unsigned.UChar.(compare u zero <> 0))",
                         "(fun b -> Unsigned.UChar.(of_int \
                          (Pervasives.compare b false)))",
                         "uchar");
    type_doc = None; }
  
let char =
  { type_name = "char"; 
    type_def = `Builtin;
    type_ctypes = `Builtin "uchar"; 
    type_doc = None; }

let int8 = 
  { type_name = "int8"; 
    type_def = `Alias "int"; 
    type_ctypes = `Builtin "char"; 
    type_doc = None; }

let uint8 = 
  { type_name = "uint8"; 
    type_def = `Alias "int"; 
    type_ctypes = `View ("int_as_uint8_t", 
                         "Unsigned.UInt8.to_int", "Unsigned.UInt8.of_int",
                         "uint8_t"); 
    type_doc = None; }

let int16 = 
  { type_name = "int16"; 
    type_def = `Alias "int"; 
    type_ctypes = `Builtin "short"; 
    type_doc = None }

let uint16 = 
  { type_name = "uint16"; 
    type_def = `Alias "int"; 
    type_ctypes = `Builtin "short"; 
    type_doc = None }

let int = 
  { type_name = "int"; 
    type_def = `Builtin; 
    type_ctypes = `Builtin "int";
    type_doc = None }

let intptr = int
let sizeiptr = int        
let sizei = int

let uint =
  { type_name = "int";
    type_def = `Builtin; 
    type_ctypes = `View ("int_as_uint", 
                      "Unsigned.UInt.to_int", "Unsigned.UInt.of_int", 
                      "uint"); 
    type_doc = None; }

let int32 =
  { type_name = "int32"; 
    type_def = `Builtin; 
    type_ctypes = `Builtin "int32_t"; 
    type_doc = None; }
  
let uint32 = 
  { type_name = "uint32"; 
    type_def = `Alias "int32"; 
    type_ctypes = `View ("int32_as_uint32_t", 
                      "Unsigned.UInt32.to_int32", "Unsigned.UInt32.of_int32",
                      "uint32_t"); 
    type_doc = None; }

let int64 =
  { type_name = "int64"; 
    type_def = `Builtin; 
    type_ctypes = `Builtin "int64_t"; 
    type_doc = None; }
  
let uint64 = 
  { type_name = "uint64"; 
    type_def = `Alias "int64"; 
    type_ctypes = `View ("int64_as_uint64_t", 
                      "Unsigned.UInt64.to_int64", "Unsigned.UInt64.of_int64",
                      "uint64_t"); 
    type_doc = None; }

let float32 = 
  { type_name = "float"; 
    type_def = `Builtin; 
    type_ctypes = `Builtin "float"; 
    type_doc = None }

let float64 = 
  { type_name = "float"; 
    type_def = `Builtin; 
    type_ctypes = `Builtin "double";
    type_doc = None; }

let clampx = 
  { uint32 with type_name = "clampx"; }

let bitfield = 
  { uint with type_name = "bitfield"; type_def = `Alias "int";} 

let enum = 
  { uint with type_name = "enum"; type_def = `Alias "int" } 

let fixed = 
  { int32 with type_name = "fixed"; type_def = `Alias "int32" }

let sync = 
  { type_name = "sync"; 
    type_def = `Abstract "unit ptr"; 
    type_ctypes = `Def ("sync", 
                        "let sync : sync typ = ptr void\n  \
                         let sync_opt : sync option typ = ptr_opt void");
    type_doc = None; }

let debug_proc = 
  { type_name = "debug_proc"; 
    type_def = `Alias "enum -> enum -> int -> enum -> string -> unit"; 
    type_ctypes = `Builtin "(assert false)"; (* Unused, manual *)
    type_doc = None; }

let void = 
  { type_name = "unit"; 
    type_def = `Builtin; 
    type_ctypes = `Builtin "void"; 
    type_doc = None }

let string = 
  { type_name = "string"; 
    type_def = `Builtin; 
    type_ctypes = `Builtin "string"; 
    type_doc = None } 

let string_opt = 
  { type_name = "string option"; 
    type_def = `Builtin; 
    type_ctypes = `Builtin "string_opt"; 
    type_doc = None }

let ba_as_voidp name =
  `View (name,
         "(fun _ -> assert false)",
         "(fun b -> to_voidp (bigarray_start array1 b))",
         "(ptr void)")

let ba_opt_as_voidp name = 
  `View (name,
         "(fun _ -> assert false)",
         "(function\n\
         \          | None -> null\n\
         \          | Some b -> to_voidp (bigarray_start array1 b))",
         "(ptr void)")

let ba_as_charp = 
  { type_name = "(char, Bigarray.int8_unsigned_elt) bigarray";
    type_def = `Builtin; 
    type_ctypes = ba_as_voidp "ba_as_charp";
    type_doc = None }

let ba_opt_as_charp = 
  { type_name = "(char, Bigarray.int8_unsigned_elt) bigarray option";
    type_def = `Builtin; 
    type_ctypes = ba_opt_as_voidp "ba_opt_as_charp";
    type_doc = None }
      
let ba_as_int8p = 
  { type_name = "(int, Bigarray.int8_signed_elt) bigarray";
    type_def = `Builtin;
    type_ctypes = ba_as_voidp "ba_as_int8p";
    type_doc = None }

let ba_as_uint8p = 
  { type_name = "(int, Bigarray.int8_unsigned_elt) bigarray";
    type_def = `Builtin;
    type_ctypes = ba_as_voidp "ba_as_uint8p";
    type_doc = None }

let ba_as_int16p = 
  { type_name = "(int, Bigarray.int16_signed_elt) bigarray";
    type_def = `Builtin;
    type_ctypes = ba_as_voidp "ba_as_int16p";
    type_doc = None }

let ba_as_uint16p = 
  { type_name = "(int, Bigarray.int16_unsigned_elt) bigarray";
    type_def = `Builtin;
    type_ctypes = ba_as_voidp "ba_as_uint16p";
    type_doc = None }

let ba_as_int32p = 
  { type_name = "(int32, Bigarray.int32_elt) bigarray";
    type_def = `Builtin;
    type_ctypes = ba_as_voidp "ba_as_int32p";
    type_doc = None }

let ba_as_uint32p = 
  { type_name = "uint32_bigarray"; 
    type_def = `Alias "(int32, Bigarray.int32_elt) bigarray";
    type_ctypes = ba_as_voidp "ba_as_uint32p";
    type_doc = None }

let ba_opt_as_uint32p = 
  { type_name = "uint32_bigarray option"; 
    type_def = `Builtin;
    type_ctypes = ba_opt_as_voidp "ba_opt_as_uint32p";
    type_doc = None }

let ba_opt_as_int32p = 
  { type_name = "(int32, Bigarray.int32_elt) bigarray option"; 
    type_def = `Builtin; 
    type_ctypes = ba_opt_as_voidp "ba_opt_as_int32p"; 
    type_doc = None }

let ba_as_enump = 
  { type_name = "enum_bigarray"; 
    type_def = `Alias "(int32, Bigarray.int32_elt) bigarray"; 
    type_ctypes = ba_as_voidp "ba_as_enump"; 
    type_doc = None }

let ba_opt_as_enump = 
  { type_name = "enum_bigarray option"; 
    type_def = `Builtin;
    type_ctypes = ba_opt_as_voidp "ba_opt_as_enump"; 
    type_doc = None }

let ba_as_nativeintp = 
  { type_name = "(nativeint, Bigarray.nativeint_elt) bigarray"; 
    type_def = `Builtin;
    type_ctypes = ba_as_voidp "ba_as_nativeint";
    type_doc = None }

let ba_opt_as_nativeintp = 
  { type_name = "(nativeint, Bigarray.nativeint_elt) bigarray option"; 
    type_def = `Builtin; 
    type_ctypes = ba_opt_as_voidp "ba_opt_as_nativeint";
    type_doc = None }

let ba_as_float32p = 
  { type_name = "(float, Bigarray.float32_elt) bigarray";
    type_def = `Builtin;
    type_ctypes = ba_as_voidp "ba_as_float32p";
    type_doc = None }
  
let ba_as_float64p = 
  { type_name = "(float, Bigarray.float64_elt) bigarray";
    type_def = `Builtin;
    type_ctypes = ba_as_voidp "ba_as_float64p";
    type_doc = None }

let ba_as_int64p = 
  { type_name = "(int64, Bigarray.int64_elt) bigarray";
    type_def = `Builtin;
    type_ctypes = ba_as_voidp "ba_as_int64p";
    type_doc = None }

let ba_as_uint64p = 
  { type_name = "uint64_bigarray"; 
    type_def = `Alias "(int64, Bigarray.int64_elt) bigarray";
    type_ctypes = ba_as_voidp "ba_as_uint64p";
    type_doc = None }

let ba_as_voidp = 
  (* Need to wrap because of the value restriction, can't make a view. *)
  let pp_wrap ppf arg = 
    pp ppf 
    "@[let %s = to_voidp (bigarray_start array1 %s) in@]" arg arg 
  in
  { type_name = "('a, 'b) bigarray";
    type_def = `Builtin; 
    type_ctypes = `Builtin_wrap_in ("(ptr void)", pp_wrap);
    type_doc = None; }

let ba_opt_as_voidp = 
  (* Need to wrap because of the value restriction, can't make a view. *)
  let pp_wrap ppf arg = 
    pp ppf 
    "@[let %s = match %s with@\n\
     | None -> null | Some b -> to_voidp (bigarray_start array1 b)@\n\
     in@]" arg arg 
  in
  { type_name = "('a, 'b) bigarray option";
    type_def = `Builtin; 
    type_ctypes = `Builtin_wrap_in ("(ptr void)", pp_wrap);
    type_doc = None }

let ba_or_offset_as_voidp = 
  (* Need to wrap because of the value restriction, can't make a view. *)
  let pp_wrap ppf arg = 
    pp ppf 
      "@[let %s = match %s with@\n\
         | `Offset o -> ptr_of_raw_address (Int64.of_int o)@\n\
         | `Data b -> to_voidp (bigarray_start array1 b)@\n\
         in@]" arg arg
  in
  { type_name = "[ `Offset of int | `Data of ('a, 'b) bigarray ]"; 
    type_def = `Builtin; 
    type_ctypes = `Builtin_wrap_in ("(ptr void)", pp_wrap); 
    type_doc = None }
     
let type_def api t = 
  let no_def t = 
    let t = Capi.type_to_string t in
    `Unknown (err_no_type_def t)
  in
  match t with
  | `Base b as t -> 
      begin match b with
      | `GLDEBUGPROC -> `Ok debug_proc
      | `GLbitfield -> `Ok bitfield 
      | `GLboolean -> `Ok bool
      | `GLbyte -> `Ok int8
      | `GLchar -> `Ok char
      | `GLclampx -> `Ok clampx
      | `GLdouble -> `Ok float64
      | `GLenum -> `Ok enum
      | `GLfixed -> `Ok fixed
      | `GLfloat -> `Ok float32
      | `GLint -> `Ok int
      | `GLint64 -> `Ok int64
      | `GLintptr -> `Ok intptr
      | `GLshort -> `Ok int16
      | `GLsizei -> `Ok sizei
      | `GLsizeiptr -> `Ok sizeiptr
      | `GLsync -> `Ok sync
      | `GLubyte -> `Ok uint8
      | `GLuint -> `Ok uint
      | `GLuint64 -> `Ok uint64
      | `GLushort -> `Ok uint16
      | `Void -> `Ok void
      | _ -> no_def t
      end
  | `Ptr (`Base `GLchar) -> `Ok ba_as_charp
  | `Ptr (`Ptr (`Base `Void)) -> `Ok ba_as_nativeintp
  | `Ptr (`Base base)
  | `Const (`Ptr (`Base base)) ->
      begin match base with 
      | `GLboolean -> `Ok ba_as_uint8p
      | `GLbyte -> `Ok ba_as_int8p
      | `GLchar -> `Ok string (* `Const, see above for non `Const *)
      | `GLdouble -> `Ok ba_as_float64p
      | `GLenum -> `Ok ba_as_enump
      | `GLfloat -> `Ok  ba_as_float32p
      | `GLint -> `Ok ba_as_int32p
      | `GLint64 -> `Ok ba_as_int64p
      | `GLshort -> `Ok ba_as_uint16p
      | `GLsizei -> `Ok ba_as_int32p
      | `GLubyte -> `Ok ba_as_uint8p
      | `GLuint -> `Ok ba_as_uint32p
      | `GLuint64 -> `Ok ba_as_uint64p
      | `GLushort -> `Ok ba_as_uint16p
      | `Void -> `Ok ba_as_voidp
      | `Void_or_index -> `Ok ba_or_offset_as_voidp
      | b -> no_def t
      end
  | `Nullable (`Ptr (`Base `GLchar)) -> `Ok ba_opt_as_charp
  | `Nullable (`Ptr (`Base `GLubyte)) -> `Ok ba_opt_as_charp
  | `Nullable (`Ptr (`Base base))
  | `Nullable (`Const (`Ptr (`Base base))) ->
      begin match base with 
      | `GLchar -> `Ok string_opt (* `Const see above for non `Const *) 
      | `GLenum -> `Ok ba_as_enump
      | `GLintptr -> `Ok ba_opt_as_nativeintp
      | `GLsizei -> `Ok ba_opt_as_int32p
      | `GLsizeiptr -> `Ok ba_opt_as_nativeintp
      | `GLubyte -> `Ok string_opt (* `Const see above for non `Const *)
      | `GLuint -> `Ok ba_opt_as_uint32p
      | `Void -> `Ok ba_opt_as_voidp
      | _ -> no_def t
      end
  | _ -> no_def t

(* OCaml function definitions *) 

type arg = { arg_name : string; arg_type : typ }
type fun_def = 
  [ `Derived of arg list * typ 
  | `Manual of string * string
  | `Unknown 
  | `Unbound of string ]

type func = 
  { fun_name : string; 
    fun_c : Capi.func;
    fun_def : fun_def;
    fun_doc : string option; } 

let fun_name api f = (* remove `gl', uncamlcase, lowercase *)
  let cname = fst f in
  if not (String.length cname > 3 && String.sub cname 0 2 = "gl") 
  then failwith (err_odd_fname cname)
  else
  let is_upper c = 'A' <= c && c <= 'Z' in
  let is_digit c = '0' <= c && c <= '9'  in
  let buf = Buffer.create (String.length cname) in
  let last_up = ref true (* avoids prefix by _ *) in
  for i = 2 to String.length cname - 1 do
    if is_upper cname.[i] &&
       not (!last_up) &&
       not (is_digit (cname.[i - 1])) (* maps eg 2D to 2d not 2_d *)
    then (Buffer.add_char buf '_'; last_up := true)
    else (last_up := false);
    Buffer.add_char buf (Char.lowercase cname.[i]);
  done;
  identifier (Buffer.contents buf)

let derived_doc = function
| "glMultiDrawElements" | "glMultiDrawElementsBaseVertex" -> 
    Some "{b Note.} [indices] are byte offsets in the buffer bound on \
          {!Gl.element_array_buffer}. Directly specifiying index arrays \
          is unsupported."
| _ -> None
  
let derived api (fn, (cargs, cret) as cdef) = 
  let arg_type t = 
    let t = match t with  
    | `Const (`Ptr (`Const (`Ptr (`Base `Void)))) -> 
        begin match fn with
        | "glMultiDrawElements" (* See derived_doc for an explanation. *) 
        | "glMultiDrawElementsBaseVertex" -> `Const (`Ptr (`Base `Void))
        | _ -> t
        end
    | t -> t
    in
    match type_def api t with 
    | `Unknown _ -> raise Exit 
    | `Ok def -> def
  in
  let ret_type = arg_type  (* nothing special for now *) in
  let arg a = 
    { arg_name = a.Capi.arg_name; 
      arg_type = arg_type a.Capi.arg_type } 
  in
  try 
    let fun_name = fun_name api cdef in
    let fun_def = `Derived (List.map arg cargs, ret_type cret) in 
    Some { fun_name; fun_c = cdef; fun_def; fun_doc = derived_doc fn }
  with Exit -> None

let unbound api f = (* unbound functions, list them here *)
  None

let manual api (fn, _ as cdef) = match Manual.get api fn with 
  | None -> None
  | Some def -> 
      Some { fun_name = fun_name api cdef; fun_c = cdef; 
             fun_def = `Manual def; fun_doc = None }
        
let funs api = 
  let func cdef = match unbound api cdef with 
  | Some r -> r
  | None -> 
      match manual api cdef with 
      | Some f -> f 
      | None -> 
          match derived api cdef with 
          | Some f -> f
          | None -> 
              { fun_name = fun_name api cdef; fun_c = cdef; 
                fun_def = `Unknown; fun_doc = None }
  in
  List.map func (Capi.funs api)

let types api =
  let add_type acc t = if List.memq t acc then acc else t :: acc in
  let add_arg_type acc arg = add_type acc arg.arg_type in
  let add_types acc f = match f.fun_def with
  | `Derived (args, ret) -> 
      List.fold_left add_arg_type (add_type acc ret) args
  | _ -> acc 
  in
  let manual = [ debug_proc ] in
  List.fold_left add_types manual (funs api)
  
(* Enum value definitions. *) 

type enum = 
  { enum_name : string;
    enum_c_name : string; 
    enum_value : Capi.enum_value }

let enums api = 
  let add_fname acc f = Sset.add (fun_name api f) acc in
  let fun_names = List.fold_left add_fname Sset.empty (Capi.funs api) in
  let enum (cname, v) = 
    (* remove `GL_`, lowercase, fix clashes with fun names *) 
    if not (String.length cname > 3 && (String.sub cname 0 3) = "GL_")
    then failwith (err_odd_ename cname)
    else
    let n = String.lowercase (String.sub cname 3 (String.length cname - 3)) in
    let n = identifier n in
    let n = if Sset.mem n fun_names then n ^ "_enum" else n in
    { enum_name = n; enum_c_name = cname; enum_value = v }
  in
  List.map enum (Capi.enums api)

(*---------------------------------------------------------------------------
   Copyright (c) 2013 Daniel C. Bünzli.
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
