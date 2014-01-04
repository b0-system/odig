(*---------------------------------------------------------------------------
   Copyright (c) 2013 Daniel C. Bünzli. All rights reserved.
   Distributed under the BSD3 license, see license at the end of the file.
   %%NAME%% release %%VERSION%%
  ---------------------------------------------------------------------------*)

let pp = Format.fprintf
let pp_str = Format.pp_print_string 
let pp_opt pp_v ppf v = match v with 
| None -> () | Some v -> pp ppf "%a" pp_v v

(* mli API Doc *)

let pp_mli_api_header ppf api = 
  let syn = Oapi.doc_synopsis api in
  let lsyn = Oapi.doc_synopsis_long api in 
  let profile = Capi.profile api in
  let lib_module = Oapi.module_lib api in 
  let bind_module = Oapi.module_bind api in
  pp ppf 
"\
(** %s thin bindings.

    [%s] can program %a %s contexts.
    Consult the {{!conventions}binding conventions}.

    Open the module use it, this defines only the module [%s]
    in your scope. To use in the toplevel with [findlib], 
    just [#require \"%s\"], it automatically loads the library and 
    opens the [%s] module.

    {b References} 
    {ul 
    {- {{:%s}%s}}}

    {e Release %%%%VERSION%%%% — %s — %%%%MAINTAINER%%%% } *)
@\n"
  syn lib_module (pp_opt pp_str) profile lsyn bind_module
  (String.lowercase lib_module) lib_module (Doc.home_uri api) syn syn

let pp_mli_api_footer ppf api = 
  let lib_module = Oapi.module_lib api in 
  let bind_module = Oapi.module_bind api in
  pp ppf 
"\
(** {1:conventions Conventions}

    To find the name of an OCaml function corresponding to a C
    function name, map the [gl] prefix to the module name 
    {!%s.%s},
    add an underscore between each minuscule and majuscule and lower
    case the result. For example [glGetError] maps to
    {!%s.%s.get_error}

    To find the name of an OCaml value corresponding to a C enumerant name,
    map the [GL_] prefix to the module name {!%s.%s} 
    and lower case the rest. For example [GL_COLOR_BUFFER_BIT] maps to 
    {!%s.%s.color_buffer_bit}. 

    The following exceptions occur:
    {ul
    {- A few enumerant names do clash with functions name. In that case we 
       postfix the enumerant name with [_enum]. For example we have 
       {!%s.%s.viewport} and {!%s.%s.viewport_enum}.}
    {- If applying the above procedures results in an identifier that 
       doesn't start with a letter, prefix the identifier with a ['_'].} 
    {- If applying the above procedures results in an identifier that 
       is an OCaml keyword, suffix the identifier with a ['_'].}} *)
@\n" lib_module bind_module lib_module bind_module lib_module bind_module 
     lib_module bind_module lib_module bind_module lib_module bind_module 

(* License *)

let pp_license_header ppf () = 
  let invocation = String.concat " " (Array.to_list Sys.argv) in
  pp ppf
"\
(*---------------------------------------------------------------------------
   Copyright (c) 2013 Daniel C. Bünzli. All rights reserved.
   Distributed under the BSD3 license, see license at the end of the file.
   %%NAME%% release %%VERSION%%
  ---------------------------------------------------------------------------*)

(* WARNING do not edit. This file was automatically generated with:
   %s *)
@\n" invocation


let pp_license_footer ppf () =
  pp ppf
"\
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
   \"AS IS\" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
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
"

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
