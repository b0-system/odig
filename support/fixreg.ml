(*---------------------------------------------------------------------------
   Copyright (c) 2013 Daniel C. Bünzli. All rights reserved.
   Distributed under the BSD3 license, see license at the end of the file.
   %%NAME%% release %%VERSION%%
  ---------------------------------------------------------------------------*)

(* The registry doesn't provide us that info. *) 

let is_arg_nullable f a = match f with 
| "glObjectLabel" -> a = "label"
| "glObjectPtrLabel" -> a = "label"
| "glBindImageTextures" -> a = "textures"
| "glBindBuffersBase" -> a = "buffers"
| "glBindBuffersRange" -> 
    (match a with "buffers" | "offsets" | "sizes" -> true | _ -> false)
| "glBindSamplers" -> a = "samplers"
| "glBindTextures" -> a = "textures" 
| "glBindVertexBuffers" -> 
    (match a with "buffers" | "offsets" | "strides" -> true | _ -> false)
| "glBufferData" 
| "glBufferSubData"
| "glBufferStorage"
| "glClearBufferData"
| "glClearBufferSubData" 
| "glClearTexImage"
| "glClearTexSubImage" -> a = "data"
| "glDebugMessageControl" -> a = "ids"
| "glGetDebugMessageLog" -> 
    begin match a with 
     | "sources" | "types" | "ids" | "severities" | "lengths" 
     | "messageLog" -> true
     | _ -> false
    end
| "glGetAttachedShaders" -> a = "count"
| "glGetProgramBinary" | "glGetActiveAttrib" | "glGetActiveSubroutineName" 
| "glGetActiveSubroutineUniformName" | "glGetActiveUniform"
| "glGetActiveUniformBlockName" | "glGetActiveUniformName" 
| "glGetObjectLabel" | "glGetObjectPtrLabel" | "glGetProgramInfoLog" 
| "glGetProgramPipelineInfoLog" | "glGetProgramResourceName" 
| "glGetShaderInfoLog" | "glGetShaderSource" | "glGetSynciv" 
| "glGetTransformFeedbackVarying" ->
    a = "length"
| _ -> false 

let is_ret_nullable = function
| "glGetString" | "glGetStringi" -> true
| _ -> false

let is_arg_voidp_or_index f a = match f with 
  | "glTexImage1D" | "glTexImage2D" | "glTexImage3D" 
  | "glTexSubImage1D" | "glTexSubImage2D" | "glTexSubImage3D" -> 
      a = "pixels"
  | "glCompressedTexImage1D" | "glCompressedTexImage2D" 
  | "glCompressedTexImage3D" 
  | "glCompressedTexSubImage1D" | "glCompressedTexSubImage2D" 
  | "glCompressedTexSubImage3D" -> 
      a = "data" 
  | "glDrawElements" | "glDrawElementsBaseVertex" 
  | "glDrawElementsInstanced" | "glDrawElementsInstancedBaseInstance" 
  | "glDrawElementsInstancedBaseVertex" 
  | "glDrawElementsInstancedBaseVertexBaseInstance" 
  | "glDrawRangeElements" | "glDrawRangeElementsBaseVertex" ->
      a = "indices"
  | "glDrawArraysIndirect" | "glDrawElementsIndirect" 
  | "glMultiDrawArraysIndirect" | "glMultiDrawElementsIndirect" -> 
      a = "indirect"
  | "glVertexAttribPointer" | "glVertexAttribIPointer" 
  | "glVertexAttribLPointer" -> 
      a = "pointer"
  | "glGetCompressedTexImage" | "glGetTexImage" -> a = "img" 
  | "glReadPixels" -> a = "data"
  | _ -> false

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
