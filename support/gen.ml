(*---------------------------------------------------------------------------
   Copyright (c) 2013 Daniel C. Bünzli. All rights reserved.
   Distributed under the BSD3 license, see license at the end of the file.
   %%NAME%% release %%VERSION%%
  ---------------------------------------------------------------------------*)

let str = Printf.sprintf 
let pp = Format.fprintf 
let pp_nop ppf () = ()
let rec pp_list ?(pp_sep = Format.pp_print_cut) pp_v ppf = function 
| [] -> ()
| v :: vs -> 
    pp_v ppf v; if vs <> [] then (pp_sep ppf (); pp_list ~pp_sep pp_v ppf vs)

let pp_text ?(verb = false) ppf s = 
  (* hint spaces and new lines with Format's funs *)
  let len = String.length s in
  let left = ref 0 in
  let right = ref 0 in 
  let flush () =
    Format.pp_print_string ppf (String.sub s !left (!right - !left)); 
    incr right; left := !right; 
  in
  while (!right <> len) do 
    if s.[!right] = '\n' then (flush (); Format.pp_force_newline ppf ()) else
    if s.[!right] = ' ' && not verb then 
      (flush (); Format.pp_print_space ppf ()) 
    else 
    incr right
  done;
  if !left <> len then flush ()

(* Type generation. *) 

let pp_mli_type api ppf t = 
  let pp_doc () = match t.Oapi.type_doc with 
  | None -> ()
  | Some t -> pp ppf "@[(** %s *)@]@,@," t
  in
  begin match t.Oapi.type_def with
  | `Builtin -> () 
  | `Alias a -> pp ppf "@[type %s = %s@]@," t.Oapi.type_name a; pp_doc ()
  | `Abstract _ -> pp ppf "@[type %s@]@," t.Oapi.type_name; pp_doc ()
  end

let pp_ml_type acc api ppf t = (* [acc] remembers views already printed *)
  begin match t.Oapi.type_def with 
  | `Builtin -> ()
  | `Alias a | `Abstract a -> 
      pp ppf "@[type %s = %s@]@," t.Oapi.type_name a;
  end;
  begin match t.Oapi.type_ctypes with 
  | `Builtin _ | `Builtin_wrap_in _ -> acc
  | `Def (n, s) ->
      if List.mem n acc then acc else (pp ppf "@[%s@]@,@," s; n :: acc)
  | `View (n, r, w, t) -> 
      if List.mem n acc then acc else 
      (pp ppf "@[let %s =@\n\
                 \  view ~read:%s@\n\
                 \       ~write:%s@\n\
                 \       %s@]@,@," n r w t; n :: acc)
  end

let pp_ml_types api ppf l = 
  let rec loop acc = function 
    | t :: ts -> loop (pp_ml_type acc api ppf t) ts
    | [] -> ()
  in
  loop [] l

let sort_types ts = 
  let compare t t' = 
    (* Only [debug_proc] depends on the others, put it at the end. 
       We then generate defs in the order given by this function. *)
    if t.Oapi.type_name = "debug_proc" then 1 else 
    if t'.Oapi.type_name = "debug_proc" then -1 else
    compare t t'
  in
  List.sort compare ts 
  
(* Function generation. *) 

let pp_linked_fun_name ~log api ppf f = match Doc.man_uri api f with 
| Some uri -> pp ppf "@[{{:%s}@,[%s]}@]" uri f
| None -> 
    pp log "W: No documentation URI for function `%s'@." f; 
    pp ppf "[%s]" f

let pp_mli_fun ~log api ppf f = match f.Oapi.fun_def with
| `Manual (mli, _) -> pp ppf "@[%a@]" (pp_text ~verb:true) mli
| `Unbound _ -> assert false
| `Unknown -> 
    let cname, _ = f.Oapi.fun_c in
    pp log "W: `%s` unknown, generating failing stub.@\n" cname; 
    pp ppf "@[val %s@ : unit@ -> unit@]@," f.Oapi.fun_name;
    pp ppf "(** @[\xE2\x9C\x98 %a *)@]@," (pp_linked_fun_name ~log api) cname
| `Derived (args, ret) -> 
    let pp_arg_typ ppf a = pp ppf "%s" Oapi.(a.arg_type.type_name) in
    let pp_arg_typ_sep ppf () = pp ppf " ->@ " in
    let pp_arg ppf a = match a.Oapi.arg_name with
    | "" -> pp ppf "()" 
    | a -> pp ppf "%s" (Oapi.identifier a)
    in
    let pp_arg_sep ppf () = pp ppf "@ " in
    let pp_doc ppf d = match d with 
    | None -> () | Some d -> pp ppf "@,@,@[%a@]" (pp_text ~verb:false) d 
    in
    let fname = f.Oapi.fun_name in
    let cname, _ = f.Oapi.fun_c in 
    pp ppf "@[<2>val %s@ : %a ->@ %s@]@,"
      fname (pp_list ~pp_sep:pp_arg_typ_sep pp_arg_typ) args 
      ret.Oapi.type_name; 
    pp ppf "(** @[<v>@[<2>%a@ [%a]@]%a *)@]@,"
      (pp_linked_fun_name ~log api) cname
      (pp_list ~pp_sep:pp_arg_sep pp_arg) args 
      pp_doc f.Oapi.fun_doc
     
let ctypes_name t = match t.Oapi.type_ctypes with 
| `Builtin c | `Builtin_wrap_in (c, _) | `Def (c, _) | `View (c, _, _, _) -> c

let must_wrap args =
  let must_wrap a = match Oapi.(a.arg_type.type_ctypes) with 
  | `Builtin_wrap_in (c, _) -> true | _ -> false 
  in
  List.exists must_wrap args

let pp_arg_wrap ppf a = match Oapi.(a.arg_type.type_ctypes) with 
| `Builtin_wrap_in (_, pp_wrap) -> 
    pp ppf "%a@," pp_wrap Oapi.(identifier a.arg_name)
| _ -> ()

let pp_ml_fun ~log api ppf f = match f.Oapi.fun_def with 
| `Manual (_, ml) -> pp ppf "@[%a@]" (pp_text ~verb:true) ml
| `Unbound _ -> assert false
| `Unknown -> 
    let cname, _ = f.Oapi.fun_c in
    pp ppf "@[<2>let %s _ =@ failwith \"%s\"@]@," f.Oapi.fun_name cname
| `Derived (args, ret) -> 
    let pp_arg_ctype ppf a = pp ppf "%s" (ctypes_name a.Oapi.arg_type) in
    let pp_sep ppf () = pp ppf " @@->@ " in
    let fname = f.Oapi.fun_name in
    let cname, _ = f.Oapi.fun_c in
    pp ppf "@[<2>let %s =@\n@[<2>foreign ~stub \"%s\"@ \
            @[<1>(%a @@->@ returning %s)@]@]@]@,"
      fname cname (pp_list ~pp_sep pp_arg_ctype) args (ctypes_name ret); 
    if not (must_wrap args) then () else 
    let pp_arg_name ppf a = pp ppf "%s" Oapi.(identifier a.arg_name) in
    pp ppf "@,@[<2>let %s @[%a@] =@\n@[<v>%a@]@[<2>%s %a@]@]@," 
      fname
      (pp_list ~pp_sep:Format.pp_print_space pp_arg_name) args 
      (pp_list ~pp_sep:(fun ppf () -> ()) pp_arg_wrap) args
      fname
      (pp_list ~pp_sep:Format.pp_print_space pp_arg_name) args 

(* Enum generation *)

let pp_ml_enum_value ppf = function 
| `GLenum e -> pp ppf "0x%X" e
| `GLuint i -> pp ppf "0x%lXl" i
| `GLuint64 i -> pp ppf "0x%LXL" i
  
let pp_mli_enum_type ppf = function 
| `GLenum e -> pp ppf "enum"
| `GLuint i -> pp ppf "int32"
| `GLuint64 i -> pp ppf "int64"

let pp_mli_enum api ppf e = 
  pp ppf "@[val %s : %a@]@," 
    e.Oapi.enum_name pp_mli_enum_type e.Oapi.enum_value

let pp_ml_enum api ppf e = 
  pp ppf "@[<2>let %s =@ %a@]" 
    e.Oapi.enum_name pp_ml_enum_value e.Oapi.enum_value

(* Module signature generation *) 
      
let pp_mli_module ~log ppf api = 
  let synopsis = Oapi.doc_synopsis api in
  pp ppf 
    "@[<v>\
     (** {1 %s} *)@,@,\
     (** @[<v>%s bindings.@,@,\
         @[{{!types}Types},@ {{!funs}functions}@ and@ {{!enums}enumerants}. *)\
         @]@]@,\
     module %s : sig@,@,\
     \  (** {1:ba Bigarrays} *)@,@,\
     \  type ('a, 'b) bigarray = ('a,'b, Bigarray.c_layout) \
        Bigarray.Array1.t@,@,\
     \  val bigarray_byte_size : ('a, 'b) bigarray -> int@,\
     \  (** [bigarray_byte_size ba] is the size of [ba] in bytes. *)@,@,\
     \  val string_of_bigarray : \
        (char, Bigarray.int8_unsigned_elt) bigarray -> string@,\
     \  (** [string_of_bigarray ba] is [ba] until the first ['\\x00'], as a \
        string. *)@,@,\
     \  (** {1:types Types} *)@,@,\
     \  @[<v>%a@]@,\
     \  (** {1:funs Functions} *)@,@,\
     \  @[<v>%a@]@,\
     \  (** {1:enums Enums} *)@,@,\
     \  @[<v>%a@]@,\
     end@,@,@]" 
    synopsis synopsis (Oapi.module_bind api)
    (pp_list ~pp_sep:pp_nop (pp_mli_type api))
    (sort_types (Oapi.types api))
    (pp_list (pp_mli_fun ~log api))
    (Oapi.funs api)
    (pp_list (pp_mli_enum api))
    (Oapi.enums api)
  
let pp_api_mli ~log ppf api = 
  Genpp.pp_license_header ppf ();
  Genpp.pp_mli_api_header ppf api;
  pp_mli_module ~log ppf api;
  Genpp.pp_mli_api_footer ppf api; 
  Genpp.pp_license_footer ppf ();
  ()

(* Module implementation generation *) 

let pp_ml_module ~log ppf api =
  pp ppf 
    "@[<v>\
     open Ctypes@,\
     open Foreign@,@,\
     (* %s bindings *)@,@,\
     module %s = struct@,@,\
     \  (* Bigarrays *)@,@,\
     \  type ('a, 'b) bigarray = ('a,'b, Bigarray.c_layout) \
        Bigarray.Array1.t@,@,\
     \  let ba_kind_byte_size : ('a, 'b) Bigarray.kind -> int = fun k ->@,\
     \    let open Bigarray in@,\
     \    (* FIXME: see http://caml.inria.fr/mantis/view.php?id=6263 *)@,\
     \    match Obj.magic k with@,\
     \    | k when k = char || k = int8_signed || k = int8_unsigned -> 1@,\
     \    | k when k = int16_signed || k = int16_unsigned -> 2@,\
     \    | k when k = int32 || k = float32 -> 4@,\
     \    | k when k = float64 || k = int64 || k = complex32 -> 8@,\
     \    | k when k = complex64 -> 16@,\
     \    | k when k = int || k = nativeint -> Sys.word_size / 8@,\
     \    | k -> assert false@,@,\
     \ let bigarray_byte_size ba =@,\
     \   let el_size = ba_kind_byte_size (Bigarray.Array1.kind ba) in@,\
     \   el_size * Bigarray.Array1.dim ba@,@,\
     \ let access_ptr_typ_of_ba_kind : ('a, 'b) Bigarray.kind -> 'a ptr typ =@,\
     \   fun k ->@,\
     \   let open Bigarray in@,\
     \   (* FIXME: use typ_of_bigarray_kind when ctypes support it. *)@,\
     \   match Obj.magic k with@,\
     \   | k when k = float32 -> Obj.magic (ptr Ctypes.float)@,\
     \   | k when k = float64 -> Obj.magic (ptr Ctypes.double)@,\
     \   | k when k = complex32 -> Obj.magic (ptr Ctypes.complex32)@,\
     \   | k when k = complex64 -> Obj.magic (ptr Ctypes.complex64)@,\
     \   | k when k = int8_signed -> Obj.magic (ptr Ctypes.int8_t)@,\
     \   | k when k = int8_unsigned -> Obj.magic (ptr Ctypes.uint8_t)@,\
     \   | k when k = int16_signed -> Obj.magic (ptr Ctypes.int16_t)@,\
     \   | k when k = int16_unsigned -> Obj.magic (ptr Ctypes.uint16_t)@,\
     \   | k when k = int -> Obj.magic (ptr Ctypes.camlint)@,\
     \   | k when k = int32 -> Obj.magic (ptr Ctypes.int32_t)@,\
     \   | k when k = int64 -> Obj.magic (ptr Ctypes.int64_t)@,\
     \   | k when k = nativeint -> Obj.magic (ptr Ctypes.nativeint)@,\
     \   | k when k = char -> Obj.magic (ptr Ctypes.char)@,\
     \   | _ -> assert false@,@,\
     \ let string_of_bigarray ba =@,\
     \   let len = Bigarray.Array1.dim ba in@,\
     \   let b = Buffer.create (len - 1) in@,\
     \   try@,\
     \     for i = 0 to len - 1 do@,\
     \       if ba.{i} = '\\x00' then raise Exit else Buffer.add_char b \
             ba.{i}@,\
     \     done;@,\
     \     raise Exit;@,\
     \   with Exit -> Buffer.contents b@,@,\
     \  (* Types *)@,@,\
     \  @[<v>%a@]@,\
     \  (* Functions *)@,@,\
     \  let stub = true@,@,\
     \  @[<v>%a@]@,@,\
     \  (* Enums *)@,@,\
     \  @[<v>%a@]@,\
     end@,@,@]"
    (Oapi.doc_synopsis api) (Oapi.module_bind api)
    (pp_ml_types api) 
    (sort_types (Oapi.types api))
    (pp_list (pp_ml_fun ~log api)) 
    (Oapi.funs api)
    (pp_list (pp_ml_enum api)) 
    (Oapi.enums api)

let pp_api_ml ~log ppf api = 
  Genpp.pp_license_header ppf ();
  pp_ml_module ~log ppf api;
  Genpp.pp_license_footer ppf ();
  ()

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
