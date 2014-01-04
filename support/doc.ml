(*---------------------------------------------------------------------------
   Copyright (c) 2013 Daniel C. Bünzli. All rights reserved.
   Distributed under the BSD3 license, see license at the end of the file.
   %%NAME%% release %%VERSION%%
  ---------------------------------------------------------------------------*)

let str = Printf.sprintf

module Smap = Map.Make(String)

let fun_page_map = ref Smap.empty (* Filled at the end of the module *) 
let fun_to_page f = try Some (Smap.find f !fun_page_map) with Not_found -> None
let page_uri uri f = match fun_to_page f with
| None -> None | Some page -> Some (uri page)

let default = 
  ("http://www.opengl.org", fun _ -> None)

let docs_GL_ES_1_0 = 
  let home = "http://www.khronos.org/opengles/1_X" in
  let man_base = "http://www.khronos.org/opengles/sdk/1.1/docs/man/" in
  let man = page_uri (str "%s%s.xml" man_base) in
  (home, man)
  
let docs_GL_ES_2_0 = 
  let home = "http://www.khronos.org/opengles/2_X" in
  let man_base = "http://www.khronos.org/opengles/sdk/docs/man/" in
  let man = page_uri (str "%sxhtml/%s.xml" man_base) in
  (home, man)
  
let docs_GL_ES_3_0 = 
  let home = "http://www.khronos.org/opengles/3_X" in
  let man_base  = "http://www.khronos.org/opengles/sdk/docs/man3/" in
  let man = page_uri (str "%sxhtml/%s.xml" man_base) in
  (home, man)
  
let docs_GL_3_X = 
  let home = "http://www.opengl.org/registry" in
  let man_base = "http://www.opengl.org/sdk/docs/man3/" in 
  let man = page_uri (str "%sxhtml/%s.xml" man_base) in
  (home, man)
  
let docs_GL_4_X = 
  let home = "http://www.opengl.org/registry" in
  let man_base = "http://www.opengl.org/sdk/docs/man4/" in 
  let man = page_uri (str "%sxhtml/%s.xml" man_base) in
  (home, man)
  
let docs_ext e = 
  try
    let fst = String.index_from e 0 '_' in 
    let snd = String.index_from e (fst + 1) '_' in 
    let vend = String.sub e (fst + 1) (snd - fst - 1) in
    let ext = String.sub e (snd + 1) (String.length e - snd - 1) in
    let home = str "http://www.opengl.org/registry/specs/%s/%s.txt" vend ext in 
    let man = fun _ -> None in 
    (home, man)
  with Not_found -> default 

let docs api = match Capi.id api with
| `Gl (3, _) -> docs_GL_3_X
| `Gl (4, _) -> docs_GL_4_X
| `Gles (1, _) -> docs_GL_ES_1_0
| `Gles (2, _) -> docs_GL_ES_2_0
| `Gles (3, _) -> docs_GL_ES_3_0
| `Ext e -> docs_ext e
| _ -> default

let home_uri api = fst (docs api)
let man_uri api = snd (docs api)

(* 
   Extracted from https://www.opengl.org/sdk/docs/man/xhtml/index.html 
   and manual additions. We hope the scheme is identical for all GLs. 
*)

let () = 
  fun_page_map := 
    List.fold_left (fun acc (f, page) -> Smap.add f page acc) Smap.empty [
    "glActiveShaderProgram", "glActiveShaderProgram";
    "glActiveTexture", "glActiveTexture";
    "glAttachShader", "glAttachShader";
    "glBeginConditionalRender", "glBeginConditionalRender";
    "glBeginQuery", "glBeginQuery";
    "glBeginQueryIndexed", "glBeginQueryIndexed";
    "glBeginTransformFeedback", "glBeginTransformFeedback";
    "glBindAttribLocation", "glBindAttribLocation";
    "glBindBuffer", "glBindBuffer";
    "glBindBufferBase", "glBindBufferBase";
    "glBindBufferRange", "glBindBufferRange";
    "glBindBuffersBase", "glBindBuffersBase";
    "glBindBuffersRange", "glBindBuffersRange";
    "glBindFragDataLocation", "glBindFragDataLocation";
    "glBindFragDataLocationIndexed", "glBindFragDataLocationIndexed";
    "glBindFramebuffer", "glBindFramebuffer";
    "glBindImageTexture", "glBindImageTexture";
    "glBindImageTextures", "glBindImageTextures";
    "glBindProgramPipeline", "glBindProgramPipeline";
    "glBindRenderbuffer", "glBindRenderbuffer";
    "glBindSampler", "glBindSampler";
    "glBindSamplers", "glBindSamplers";
    "glBindTexture", "glBindTexture";
    "glBindTextures", "glBindTextures";
    "glBindTransformFeedback", "glBindTransformFeedback";
    "glBindVertexArray", "glBindVertexArray";
    "glBindVertexBuffer", "glBindVertexBuffer";
    "glBindVertexBuffers", "glBindVertexBuffers";
    "glBlendColor", "glBlendColor";
    "glBlendEquation", "glBlendEquation";
    "glBlendEquationSeparate", "glBlendEquationSeparate";
    "glBlendEquationSeparatei", "glBlendEquationSeparate";
    "glBlendEquationi", "glBlendEquation";
    "glBlendFunc", "glBlendFunc";
    "glBlendFuncSeparate", "glBlendFuncSeparate";
    "glBlendFuncSeparatei", "glBlendFuncSeparate";
    "glBlendFunci", "glBlendFunc";
    "glBlitFramebuffer", "glBlitFramebuffer";
    "glBufferData", "glBufferData";
    "glBufferStorage", "glBufferStorage";
    "glBufferSubData", "glBufferSubData";
    "glCheckFramebufferStatus", "glCheckFramebufferStatus";
    "glClampColor", "glClampColor";
    "glClear", "glClear";
    "glClearBuffer", "glClearBuffer";
    "glClearBufferData", "glClearBufferData";
    "glClearBufferSubData", "glClearBufferSubData";
    "glClearBufferfi", "glClearBuffer";
    "glClearBufferfv", "glClearBuffer";
    "glClearBufferiv", "glClearBuffer";
    "glClearBufferuiv", "glClearBuffer";
    "glClearColor", "glClearColor";
    "glClearDepth", "glClearDepth";
    "glClearDepthf", "glClearDepth";
    "glClearStencil", "glClearStencil";
    "glClearTexImage", "glClearTexImage";
    "glClearTexSubImage", "glClearTexSubImage";
    "glClientWaitSync", "glClientWaitSync";
    "glColorMask", "glColorMask";
    "glColorMaski", "glColorMask";
    "glCompileShader", "glCompileShader";
    "glCompressedTexImage1D", "glCompressedTexImage1D";
    "glCompressedTexImage2D", "glCompressedTexImage2D";
    "glCompressedTexImage3D", "glCompressedTexImage3D";
    "glCompressedTexSubImage1D", "glCompressedTexSubImage1D";
    "glCompressedTexSubImage2D", "glCompressedTexSubImage2D";
    "glCompressedTexSubImage3D", "glCompressedTexSubImage3D";
    "glCopyBufferSubData", "glCopyBufferSubData";
    "glCopyImageSubData", "glCopyImageSubData";
    "glCopyTexImage1D", "glCopyTexImage1D";
    "glCopyTexImage2D", "glCopyTexImage2D";
    "glCopyTexSubImage1D", "glCopyTexSubImage1D";
    "glCopyTexSubImage2D", "glCopyTexSubImage2D";
    "glCopyTexSubImage3D", "glCopyTexSubImage3D";
    "glCreateProgram", "glCreateProgram";
    "glCreateShader", "glCreateShader";
    "glCreateShaderProgram", "glCreateShaderProgram";
    "glCreateShaderProgramv", "glCreateShaderProgram";
    "glCullFace", "glCullFace";
    "glDebugMessageCallback", "glDebugMessageCallback";
    "glDebugMessageControl", "glDebugMessageControl";
    "glDebugMessageInsert", "glDebugMessageInsert";
    "glDeleteBuffers", "glDeleteBuffers";
    "glDeleteFramebuffers", "glDeleteFramebuffers";
    "glDeleteProgram", "glDeleteProgram";
    "glDeleteProgramPipelines", "glDeleteProgramPipelines";
    "glDeleteQueries", "glDeleteQueries";
    "glDeleteRenderbuffers", "glDeleteRenderbuffers";
    "glDeleteSamplers", "glDeleteSamplers";
    "glDeleteShader", "glDeleteShader";
    "glDeleteSync", "glDeleteSync";
    "glDeleteTextures", "glDeleteTextures";
    "glDeleteTransformFeedbacks", "glDeleteTransformFeedbacks";
    "glDeleteVertexArrays", "glDeleteVertexArrays";
    "glDepthFunc", "glDepthFunc";
    "glDepthMask", "glDepthMask";
    "glDepthRange", "glDepthRange";
    "glDepthRangeArray", "glDepthRangeArray";
    "glDepthRangeArrayv", "glDepthRangeArray";
    "glDepthRangeIndexed", "glDepthRangeIndexed";
    "glDepthRangef", "glDepthRange";
    "glDetachShader", "glDetachShader";
    "glDisable", "glEnable";
    "glDisableVertexAttribArray", "glEnableVertexAttribArray";
    "glDisablei", "glEnable";
    "glDispatchCompute", "glDispatchCompute";
    "glDispatchComputeIndirect", "glDispatchComputeIndirect";
    "glDrawArrays", "glDrawArrays";
    "glDrawArraysIndirect", "glDrawArraysIndirect";
    "glDrawArraysInstanced", "glDrawArraysInstanced";
    "glDrawArraysInstancedBaseInstance", "glDrawArraysInstancedBaseInstance";
    "glDrawBuffer", "glDrawBuffer";
    "glDrawBuffers", "glDrawBuffers";
    "glDrawElements", "glDrawElements";
    "glDrawElementsBaseVertex", "glDrawElementsBaseVertex";
    "glDrawElementsIndirect", "glDrawElementsIndirect";
    "glDrawElementsInstanced", "glDrawElementsInstanced";
    "glDrawElementsInstancedBaseInstance", 
    "glDrawElementsInstancedBaseInstance";
    "glDrawElementsInstancedBaseVertex", "glDrawElementsInstancedBaseVertex";
    "glDrawElementsInstancedBaseVertexBaseInstance", 
    "glDrawElementsInstancedBaseVertexBaseInstance";
    "glDrawRangeElements", "glDrawRangeElements";
    "glDrawRangeElementsBaseVertex", "glDrawRangeElementsBaseVertex";
    "glDrawTransformFeedback", "glDrawTransformFeedback";
    "glDrawTransformFeedbackInstanced", "glDrawTransformFeedbackInstanced";
    "glDrawTransformFeedbackStream", "glDrawTransformFeedbackStream";
    "glDrawTransformFeedbackStreamInstanced", 
    "glDrawTransformFeedbackStreamInstanced";
    "glEnable", "glEnable";
    "glEnableVertexAttribArray", "glEnableVertexAttribArray";
    "glEnablei", "glEnable";
    "glEndConditionalRender", "glBeginConditionalRender";
    "glEndQuery", "glBeginQuery";
    "glEndQueryIndexed", "glBeginQueryIndexed";
    "glEndTransformFeedback", "glBeginTransformFeedback";
    "glFenceSync", "glFenceSync";
    "glFinish", "glFinish";
    "glFlush", "glFlush";
    "glFlushMappedBufferRange", "glFlushMappedBufferRange";
    "glFramebufferParameteri", "glFramebufferParameteri";
    "glFramebufferRenderbuffer", "glFramebufferRenderbuffer";
    "glFramebufferTexture", "glFramebufferTexture";
    "glFramebufferTexture1D", "glFramebufferTexture";
    "glFramebufferTexture2D", "glFramebufferTexture";
    "glFramebufferTexture3D", "glFramebufferTexture";
    "glFramebufferTextureLayer", "glFramebufferTextureLayer";
    "glFrontFace", "glFrontFace";
    "glGenBuffers", "glGenBuffers";
    "glGenFramebuffers", "glGenFramebuffers";
    "glGenProgramPipelines", "glGenProgramPipelines";
    "glGenQueries", "glGenQueries";
    "glGenRenderbuffers", "glGenRenderbuffers";
    "glGenSamplers", "glGenSamplers";
    "glGenTextures", "glGenTextures";
    "glGenTransformFeedbacks", "glGenTransformFeedbacks";
    "glGenVertexArrays", "glGenVertexArrays";
    "glGenerateMipmap", "glGenerateMipmap";
    "glGet", "glGet";
    "glGetActiveAtomicCounterBufferiv", "glGetActiveAtomicCounterBufferiv";
    "glGetActiveAttrib", "glGetActiveAttrib";
    "glGetActiveSubroutineName", "glGetActiveSubroutineName";
    "glGetActiveSubroutineUniform", "glGetActiveSubroutineUniform";
    "glGetActiveSubroutineUniformName", "glGetActiveSubroutineUniformName";
    "glGetActiveSubroutineUniformiv", "glGetActiveSubroutineUniform";
    "glGetActiveUniform", "glGetActiveUniform";
    "glGetActiveUniformBlock", "glGetActiveUniformBlock";
    "glGetActiveUniformBlockName", "glGetActiveUniformBlockName";
    "glGetActiveUniformBlockiv", "glGetActiveUniformBlock";
    "glGetActiveUniformName", "glGetActiveUniformName";
    "glGetActiveUniformsiv", "glGetActiveUniformsiv";
    "glGetAttachedShaders", "glGetAttachedShaders";
    "glGetAttribLocation", "glGetAttribLocation";
    "glGetBooleani_v", "glGet";
    "glGetBooleanv", "glGet";
    "glGetBufferParameter", "glGetBufferParameter";
    "glGetBufferParameteri64v", "glGetBufferParameter";
    "glGetBufferParameteriv", "glGetBufferParameter";
    "glGetBufferPointerv", "glGetBufferPointerv";
    "glGetBufferSubData", "glGetBufferSubData";
    "glGetCompressedTexImage", "glGetCompressedTexImage";
    "glGetDebugMessageLog", "glGetDebugMessageLog";
    "glGetDoublei_v", "glGet";
    "glGetDoublev", "glGet";
    "glGetError", "glGetError";
    "glGetFloati_v", "glGet";
    "glGetFloatv", "glGet";
    "glGetFragDataIndex", "glGetFragDataIndex";
    "glGetFragDataLocation", "glGetFragDataLocation";
    "glGetFramebufferAttachmentParameter", 
    "glGetFramebufferAttachmentParameter";
    "glGetFramebufferAttachmentParameteriv", 
    "glGetFramebufferAttachmentParameter";
    "glGetFramebufferParameter", "glGetFramebufferParameter";
    "glGetFramebufferParameteriv", "glGetFramebufferParameter";
    "glGetInteger64i_v", "glGet";
    "glGetInteger64v", "glGet";
    "glGetIntegeri_v", "glGet";
    "glGetIntegerv", "glGet";
    "glGetInternalformat", "glGetInternalformat";
    "glGetInternalformati64v", "glGetInternalformat";
    "glGetInternalformativ", "glGetInternalformat";
    "glGetMultisample", "glGetMultisample";
    "glGetMultisamplefv", "glGetMultisample";
    "glGetObjectLabel", "glGetObjectLabel";
    "glGetObjectPtrLabel", "glGetObjectPtrLabel";
    "glGetPointerv", "glGetPointerv";
    "glGetProgram", "glGetProgram";
    "glGetProgramBinary", "glGetProgramBinary";
    "glGetProgramInfoLog", "glGetProgramInfoLog";
    "glGetProgramInterface", "glGetProgramInterface";
    "glGetProgramInterfaceiv", "glGetProgramInterface";
    "glGetProgramPipeline", "glGetProgramPipeline";
    "glGetProgramPipelineInfoLog", "glGetProgramPipelineInfoLog";
    "glGetProgramPipelineiv", "glGetProgramPipeline";
    "glGetProgramResource", "glGetProgramResource";
    "glGetProgramResourceIndex", "glGetProgramResourceIndex";
    "glGetProgramResourceLocation", "glGetProgramResourceLocation";
    "glGetProgramResourceLocationIndex", "glGetProgramResourceLocationIndex";
    "glGetProgramResourceName", "glGetProgramResourceName";
    "glGetProgramResourceiv", "glGetProgramResource";
    "glGetProgramStage", "glGetProgramStage";
    "glGetProgramStageiv", "glGetProgramStage";
    "glGetProgramiv", "glGetProgram";
    "glGetQueryIndexed", "glGetQueryIndexed";
    "glGetQueryIndexediv", "glGetQueryIndexed";
    "glGetQueryObject", "glGetQueryObject";
    "glGetQueryObjecti64v", "glGetQueryObject";
    "glGetQueryObjectiv", "glGetQueryObject";
    "glGetQueryObjectui64v", "glGetQueryObject";
    "glGetQueryObjectuiv", "glGetQueryObject";
    "glGetQueryiv", "glGetQueryiv";
    "glGetRenderbufferParameter", "glGetRenderbufferParameter";
    "glGetRenderbufferParameteriv", "glGetRenderbufferParameter";
    "glGetSamplerParameter", "glGetSamplerParameter";
    "glGetSamplerParameterIiv", "glGetSamplerParameter";
    "glGetSamplerParameterIuiv", "glGetSamplerParameter";
    "glGetSamplerParameterfv", "glGetSamplerParameter";
    "glGetSamplerParameteriv", "glGetSamplerParameter";
    "glGetShader", "glGetShader";
    "glGetShaderInfoLog", "glGetShaderInfoLog";
    "glGetShaderPrecisionFormat", "glGetShaderPrecisionFormat";
    "glGetShaderSource", "glGetShaderSource";
    "glGetShaderiv", "glGetShader";
    "glGetString", "glGetString";
    "glGetStringi", "glGetString";
    "glGetSubroutineIndex", "glGetSubroutineIndex";
    "glGetSubroutineUniformLocation", "glGetSubroutineUniformLocation";
    "glGetSync", "glGetSync";
    "glGetSynciv", "glGetSync";
    "glGetTexImage", "glGetTexImage";
    "glGetTexLevelParameter", "glGetTexLevelParameter";
    "glGetTexLevelParameterfv", "glGetTexLevelParameter";
    "glGetTexLevelParameteriv", "glGetTexLevelParameter";
    "glGetTexParameter", "glGetTexParameter";
    "glGetTexParameterIiv", "glGetTexParameter";
    "glGetTexParameterIuiv", "glGetTexParameter";
    "glGetTexParameterfv", "glGetTexParameter";
    "glGetTexParameteriv", "glGetTexParameter";
    "glGetTransformFeedbackVarying", "glGetTransformFeedbackVarying";
    "glGetUniform", "glGetUniform";
    "glGetUniformBlockIndex", "glGetUniformBlockIndex";
    "glGetUniformIndices", "glGetUniformIndices";
    "glGetUniformLocation", "glGetUniformLocation";
    "glGetUniformSubroutine", "glGetUniformSubroutine";
    "glGetUniformSubroutineuiv", "glGetUniformSubroutine";
    "glGetUniformdv", "glGetUniform";
    "glGetUniformfv", "glGetUniform";
    "glGetUniformiv", "glGetUniform";
    "glGetUniformuiv", "glGetUniform";
    "glGetVertexAttrib", "glGetVertexAttrib";
    "glGetVertexAttribIiv", "glGetVertexAttrib";
    "glGetVertexAttribIuiv", "glGetVertexAttrib";
    "glGetVertexAttribLdv", "glGetVertexAttrib";
    "glGetVertexAttribPointerv", "glGetVertexAttribPointerv";
    "glGetVertexAttribdv", "glGetVertexAttrib";
    "glGetVertexAttribfv", "glGetVertexAttrib";
    "glGetVertexAttribiv", "glGetVertexAttrib";
    "glHint", "glHint";
    "glInvalidateBufferData", "glInvalidateBufferData";
    "glInvalidateBufferSubData", "glInvalidateBufferSubData";
    "glInvalidateFramebuffer", "glInvalidateFramebuffer";
    "glInvalidateSubFramebuffer", "glInvalidateSubFramebuffer";
    "glInvalidateTexImage", "glInvalidateTexImage";
    "glInvalidateTexSubImage", "glInvalidateTexSubImage";
    "glIsBuffer", "glIsBuffer";
    "glIsEnabled", "glIsEnabled";
    "glIsEnabledi", "glIsEnabled";
    "glIsFramebuffer", "glIsFramebuffer";
    "glIsProgram", "glIsProgram";
    "glIsProgramPipeline", "glIsProgramPipeline";
    "glIsQuery", "glIsQuery";
    "glIsRenderbuffer", "glIsRenderbuffer";
    "glIsSampler", "glIsSampler";
    "glIsShader", "glIsShader";
    "glIsSync", "glIsSync";
    "glIsTexture", "glIsTexture";
    "glIsTransformFeedback", "glIsTransformFeedback";
    "glIsVertexArray", "glIsVertexArray";
    "glLineWidth", "glLineWidth";
    "glLinkProgram", "glLinkProgram";
    "glLogicOp", "glLogicOp";
    "glMapBuffer", "glMapBuffer";
    "glMapBufferRange", "glMapBufferRange";
    "glMemoryBarrier", "glMemoryBarrier";
    "glMinSampleShading", "glMinSampleShading";
    "glMultiDrawArrays", "glMultiDrawArrays";
    "glMultiDrawArraysIndirect", "glMultiDrawArraysIndirect";
    "glMultiDrawElements", "glMultiDrawElements";
    "glMultiDrawElementsBaseVertex", "glMultiDrawElementsBaseVertex";
    "glMultiDrawElementsIndirect", "glMultiDrawElementsIndirect";
    "glObjectLabel", "glObjectLabel";
    "glObjectPtrLabel", "glObjectPtrLabel";
    "glPatchParameter", "glPatchParameter";
    "glPatchParameterfv", "glPatchParameter";
    "glPatchParameteri", "glPatchParameter";
    "glPauseTransformFeedback", "glPauseTransformFeedback";
    "glPixelStore", "glPixelStore";
    "glPixelStoref", "glPixelStore";
    "glPixelStorei", "glPixelStore";
    "glPointParameter", "glPointParameter";
    "glPointParameterf", "glPointParameter";
    "glPointParameterfv", "glPointParameter";
    "glPointParameteri", "glPointParameter";
    "glPointParameteriv", "glPointParameter";
    "glPointSize", "glPointSize";
    "glPolygonMode", "glPolygonMode";
    "glPolygonOffset", "glPolygonOffset";
    "glPopDebugGroup", "glPopDebugGroup";
    "glPrimitiveRestartIndex", "glPrimitiveRestartIndex";
    "glProgramBinary", "glProgramBinary";
    "glProgramParameter", "glProgramParameter";
    "glProgramParameteri", "glProgramParameter";
    "glProgramUniform", "glProgramUniform";
    "glProgramUniform1d", "glProgramUniform";
    "glProgramUniform1dv", "glProgramUniform";
    "glProgramUniform1f", "glProgramUniform";
    "glProgramUniform1fv", "glProgramUniform";
    "glProgramUniform1i", "glProgramUniform";
    "glProgramUniform1iv", "glProgramUniform";
    "glProgramUniform1ui", "glProgramUniform";
    "glProgramUniform1uiv", "glProgramUniform";
    "glProgramUniform2d", "glProgramUniform";
    "glProgramUniform2dv", "glProgramUniform";
    "glProgramUniform2f", "glProgramUniform";
    "glProgramUniform2fv", "glProgramUniform";
    "glProgramUniform2i", "glProgramUniform";
    "glProgramUniform2iv", "glProgramUniform";
    "glProgramUniform2ui", "glProgramUniform";
    "glProgramUniform2uiv", "glProgramUniform";
    "glProgramUniform3d", "glProgramUniform";
    "glProgramUniform3dv", "glProgramUniform";
    "glProgramUniform3f", "glProgramUniform";
    "glProgramUniform3fv", "glProgramUniform";
    "glProgramUniform3i", "glProgramUniform";
    "glProgramUniform3iv", "glProgramUniform";
    "glProgramUniform3ui", "glProgramUniform";
    "glProgramUniform3uiv", "glProgramUniform";
    "glProgramUniform4d", "glProgramUniform";
    "glProgramUniform4dv", "glProgramUniform";
    "glProgramUniform4f", "glProgramUniform";
    "glProgramUniform4fv", "glProgramUniform";
    "glProgramUniform4i", "glProgramUniform";
    "glProgramUniform4iv", "glProgramUniform";
    "glProgramUniform4ui", "glProgramUniform";
    "glProgramUniform4uiv", "glProgramUniform";
    "glProgramUniformMatrix2dv", "glProgramUniform";
    "glProgramUniformMatrix2fv", "glProgramUniform";
    "glProgramUniformMatrix2x3dv", "glProgramUniform";
    "glProgramUniformMatrix2x3fv", "glProgramUniform";
    "glProgramUniformMatrix2x4dv", "glProgramUniform";
    "glProgramUniformMatrix2x4fv", "glProgramUniform";
    "glProgramUniformMatrix3dv", "glProgramUniform";
    "glProgramUniformMatrix3fv", "glProgramUniform";
    "glProgramUniformMatrix3x2dv", "glProgramUniform";
    "glProgramUniformMatrix3x2fv", "glProgramUniform";
    "glProgramUniformMatrix3x4dv", "glProgramUniform";
    "glProgramUniformMatrix3x4fv", "glProgramUniform";
    "glProgramUniformMatrix4dv", "glProgramUniform";
    "glProgramUniformMatrix4fv", "glProgramUniform";
    "glProgramUniformMatrix4x2dv", "glProgramUniform";
    "glProgramUniformMatrix4x2fv", "glProgramUniform";
    "glProgramUniformMatrix4x3dv", "glProgramUniform";
    "glProgramUniformMatrix4x3fv", "glProgramUniform";
    "glProvokingVertex", "glProvokingVertex";
    "glPushDebugGroup", "glPushDebugGroup";
    "glQueryCounter", "glQueryCounter";
    "glReadBuffer", "glReadBuffer";
    "glReadPixels", "glReadPixels";
    "glReleaseShaderCompiler", "glReleaseShaderCompiler";
    "glRenderbufferStorage", "glRenderbufferStorage";
    "glRenderbufferStorageMultisample", "glRenderbufferStorageMultisample";
    "glResumeTransformFeedback", "glResumeTransformFeedback";
    "glSampleCoverage", "glSampleCoverage";
    "glSampleMaski", "glSampleMaski";
    "glSamplerParameter", "glSamplerParameter";
    "glSamplerParameterIiv", "glSamplerParameter";
    "glSamplerParameterIuiv", "glSamplerParameter";
    "glSamplerParameterf", "glSamplerParameter";
    "glSamplerParameterfv", "glSamplerParameter";
    "glSamplerParameteri", "glSamplerParameter";
    "glSamplerParameteriv", "glSamplerParameter";
    "glScissor", "glScissor";
    "glScissorArray", "glScissorArray";
    "glScissorArrayv", "glScissorArray";
    "glScissorIndexed", "glScissorIndexed";
    "glScissorIndexedv", "glScissorIndexed";
    "glShaderBinary", "glShaderBinary";
    "glShaderSource", "glShaderSource";
    "glShaderStorageBlockBinding", "glShaderStorageBlockBinding";
    "glStencilFunc", "glStencilFunc";
    "glStencilFuncSeparate", "glStencilFuncSeparate";
    "glStencilMask", "glStencilMask";
    "glStencilMaskSeparate", "glStencilMaskSeparate";
    "glStencilOp", "glStencilOp";
    "glStencilOpSeparate", "glStencilOpSeparate";
    "glTexBuffer", "glTexBuffer";
    "glTexBufferRange", "glTexBufferRange";
    "glTexImage1D", "glTexImage1D";
    "glTexImage2D", "glTexImage2D";
    "glTexImage2DMultisample", "glTexImage2DMultisample";
    "glTexImage3D", "glTexImage3D";
    "glTexImage3DMultisample", "glTexImage3DMultisample";
    "glTexParameter", "glTexParameter";
    "glTexParameterIiv", "glTexParameter";
    "glTexParameterIuiv", "glTexParameter";
    "glTexParameterf", "glTexParameter";
    "glTexParameterfv", "glTexParameter";
    "glTexParameteri", "glTexParameter";
    "glTexParameteriv", "glTexParameter";
    "glTexStorage1D", "glTexStorage1D";
    "glTexStorage2D", "glTexStorage2D";
    "glTexStorage2DMultisample", "glTexStorage2DMultisample";
    "glTexStorage3D", "glTexStorage3D";
    "glTexStorage3DMultisample", "glTexStorage3DMultisample";
    "glTexSubImage1D", "glTexSubImage1D";
    "glTexSubImage2D", "glTexSubImage2D";
    "glTexSubImage3D", "glTexSubImage3D";
    "glTextureView", "glTextureView";
    "glTransformFeedbackVaryings", "glTransformFeedbackVaryings";
    "glUniform", "glUniform";
    "glUniform1d", "glUniform";
    "glUniform1dv", "glUniform";
    "glUniform1f", "glUniform";
    "glUniform1fv", "glUniform";
    "glUniform1i", "glUniform";
    "glUniform1iv", "glUniform";
    "glUniform1ui", "glUniform";
    "glUniform1uiv", "glUniform";
    "glUniform2d", "glUniform";
    "glUniform2dv", "glUniform";
    "glUniform2f", "glUniform";
    "glUniform2fv", "glUniform";
    "glUniform2i", "glUniform";
    "glUniform2iv", "glUniform";
    "glUniform2ui", "glUniform";
    "glUniform2uiv", "glUniform";
    "glUniform3d", "glUniform";
    "glUniform3dv", "glUniform";
    "glUniform3f", "glUniform";
    "glUniform3fv", "glUniform";
    "glUniform3i", "glUniform";
    "glUniform3iv", "glUniform";
    "glUniform3ui", "glUniform";
    "glUniform3uiv", "glUniform";
    "glUniform4d", "glUniform";
    "glUniform4dv", "glUniform";
    "glUniform4f", "glUniform";
    "glUniform4fv", "glUniform";
    "glUniform4i", "glUniform";
    "glUniform4iv", "glUniform";
    "glUniform4ui", "glUniform";
    "glUniform4uiv", "glUniform";
    "glUniformBlockBinding", "glUniformBlockBinding";
    "glUniformMatrix2dv", "glUniform";
    "glUniformMatrix2fv", "glUniform";
    "glUniformMatrix2x3dv", "glUniform";
    "glUniformMatrix2x3fv", "glUniform";
    "glUniformMatrix2x4dv", "glUniform";
    "glUniformMatrix2x4fv", "glUniform";
    "glUniformMatrix3dv", "glUniform";
    "glUniformMatrix3fv", "glUniform";
    "glUniformMatrix3x2dv", "glUniform";
    "glUniformMatrix3x2fv", "glUniform";
    "glUniformMatrix3x4dv", "glUniform";
    "glUniformMatrix3x4fv", "glUniform";
    "glUniformMatrix4dv", "glUniform";
    "glUniformMatrix4fv", "glUniform";
    "glUniformMatrix4x2dv", "glUniform";
    "glUniformMatrix4x2fv", "glUniform";
    "glUniformMatrix4x3dv", "glUniform";
    "glUniformMatrix4x3fv", "glUniform";
    "glUniformSubroutines", "glUniformSubroutines";
    "glUniformSubroutinesuiv", "glUniformSubroutines";
    "glUnmapBuffer", "glMapBuffer";
    "glUseProgram", "glUseProgram";
    "glUseProgramStages", "glUseProgramStages";
    "glValidateProgram", "glValidateProgram";
    "glValidateProgramPipeline", "glValidateProgramPipeline";
    "glVertexAttrib", "glVertexAttrib";
    "glVertexAttrib1d", "glVertexAttrib";
    "glVertexAttrib1dv", "glVertexAttrib";
    "glVertexAttrib1f", "glVertexAttrib";
    "glVertexAttrib1fv", "glVertexAttrib";
    "glVertexAttrib1s", "glVertexAttrib";
    "glVertexAttrib1sv", "glVertexAttrib";
    "glVertexAttrib2d", "glVertexAttrib";
    "glVertexAttrib2dv", "glVertexAttrib";
    "glVertexAttrib2f", "glVertexAttrib";
    "glVertexAttrib2fv", "glVertexAttrib";
    "glVertexAttrib2s", "glVertexAttrib";
    "glVertexAttrib2sv", "glVertexAttrib";
    "glVertexAttrib3d", "glVertexAttrib";
    "glVertexAttrib3dv", "glVertexAttrib";
    "glVertexAttrib3f", "glVertexAttrib";
    "glVertexAttrib3fv", "glVertexAttrib";
    "glVertexAttrib3s", "glVertexAttrib";
    "glVertexAttrib3sv", "glVertexAttrib";
    "glVertexAttrib4Nbv", "glVertexAttrib";
    "glVertexAttrib4Niv", "glVertexAttrib";
    "glVertexAttrib4Nsv", "glVertexAttrib";
    "glVertexAttrib4Nub", "glVertexAttrib";
    "glVertexAttrib4Nubv", "glVertexAttrib";
    "glVertexAttrib4Nuiv", "glVertexAttrib";
    "glVertexAttrib4Nusv", "glVertexAttrib";
    "glVertexAttrib4bv", "glVertexAttrib";
    "glVertexAttrib4d", "glVertexAttrib";
    "glVertexAttrib4dv", "glVertexAttrib";
    "glVertexAttrib4f", "glVertexAttrib";
    "glVertexAttrib4fv", "glVertexAttrib";
    "glVertexAttrib4iv", "glVertexAttrib";
    "glVertexAttrib4s", "glVertexAttrib";
    "glVertexAttrib4sv", "glVertexAttrib";
    "glVertexAttrib4ubv", "glVertexAttrib";
    "glVertexAttrib4uiv", "glVertexAttrib";
    "glVertexAttrib4usv", "glVertexAttrib";
    "glVertexAttribBinding", "glVertexAttribBinding";
    "glVertexAttribDivisor", "glVertexAttribDivisor";
    "glVertexAttribFormat", "glVertexAttribFormat";
    "glVertexAttribI1i", "glVertexAttrib";
    "glVertexAttribI1iv", "glVertexAttrib";
    "glVertexAttribI1ui", "glVertexAttrib";
    "glVertexAttribI1uiv", "glVertexAttrib";
    "glVertexAttribI2i", "glVertexAttrib";
    "glVertexAttribI2iv", "glVertexAttrib";
    "glVertexAttribI2ui", "glVertexAttrib";
    "glVertexAttribI2uiv", "glVertexAttrib";
    "glVertexAttribI3i", "glVertexAttrib";
    "glVertexAttribI3iv", "glVertexAttrib";
    "glVertexAttribI3ui", "glVertexAttrib";
    "glVertexAttribI3uiv", "glVertexAttrib";
    "glVertexAttribI4bv", "glVertexAttrib";
    "glVertexAttribI4i", "glVertexAttrib";
    "glVertexAttribI4iv", "glVertexAttrib";
    "glVertexAttribI4sv", "glVertexAttrib";
    "glVertexAttribI4ubv", "glVertexAttrib";
    "glVertexAttribI4ui", "glVertexAttrib";
    "glVertexAttribI4uiv", "glVertexAttrib";
    "glVertexAttribI4usv", "glVertexAttrib";
    "glVertexAttribIFormat", "glVertexAttribFormat";
    "glVertexAttribIPointer", "glVertexAttribPointer";
    "glVertexAttribL1d", "glVertexAttrib";
    "glVertexAttribL1dv", "glVertexAttrib";
    "glVertexAttribL2d", "glVertexAttrib";
    "glVertexAttribL2dv", "glVertexAttrib";
    "glVertexAttribL3d", "glVertexAttrib";
    "glVertexAttribL3dv", "glVertexAttrib";
    "glVertexAttribL4d", "glVertexAttrib";
    "glVertexAttribL4dv", "glVertexAttrib";
    "glVertexAttribLFormat", "glVertexAttribFormat";
    "glVertexAttribLPointer", "glVertexAttribPointer";
    "glVertexAttribP1ui", "glVertexAttrib";
    "glVertexAttribP1uiv", "glVertexAttrib";
    "glVertexAttribP2ui", "glVertexAttrib";
    "glVertexAttribP2uiv", "glVertexAttrib";
    "glVertexAttribP3ui", "glVertexAttrib";
    "glVertexAttribP3uiv", "glVertexAttrib";
    "glVertexAttribP4ui", "glVertexAttrib";
    "glVertexAttribP4uiv", "glVertexAttrib";
    "glVertexAttribPointer", "glVertexAttribPointer";
    "glVertexBindingDivisor", "glVertexBindingDivisor";
    "glViewport", "glViewport";
    "glViewportArray", "glViewportArray";
    "glViewportArrayv", "glViewportArray";
    "glViewportIndexed", "glViewportIndexed";
    "glViewportIndexedf", "glViewportIndexed";
    "glViewportIndexedfv", "glViewportIndexed";
    "glWaitSync", "glWaitSync"; ]

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
