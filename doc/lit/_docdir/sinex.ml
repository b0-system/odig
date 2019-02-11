(*---------------------------------------------------------------------------
   Copyright (c) 2014 Daniel C. Bünzli. All rights reserved.
   Distributed under the BSD3 license, see license at the end of the file.
   lit release v0.0.0-126-g4058b8a
  ---------------------------------------------------------------------------*)

(* Sinex
   Shader is due and (c) 2012 Gaspard Bucher (http://feature-space.com/)  *)

open Gg
open Lit
open React
open Useri

let fullscreen () = (* two triangles covering the projection of clip space *)
  let attrs =
    let b = Ba.create Ba.Float32 (4 * 3) in
    Ba.set_3d b 0 ( 1.) ( 1.) ( 0.);                 (* vertices *)
    Ba.set_3d b 3 (-1.) ( 1.) ( 0.);
    Ba.set_3d b 6 ( 1.) (-1.) ( 0.);
    Ba.set_3d b 9 (-1.) (-1.) ( 0.);
    let b = Buf.create (`Float32 b) in
    [ Attr.create Attr.vertex ~dim:3 b ]
  in
  let index =
    let b = Ba.create Ba.UInt8 (2 * 3) in
    Ba.set_3d b 0 0 1 2;                            (* triangles *)
    Ba.set_3d b 3 2 1 3;
    Buf.create (`UInt8 b)
  in
  Prim.create ~index `Triangles attrs

let time = Uniform.float "time" 0.
let program =
  let view_size = Uniform.viewport_size "view_size" in
  let uset = Uniform.(add (add empty time) view_size) in
  Prog.create ~uset [
    Prog.shader `Vertex "
    in vec3 vertex;
    void main() { gl_Position = vec4(vertex, 1.0); }";

    Prog.shader `Fragment "
    float smoothcut(float e0, float e1, float v)
    {
      if (v > e1)
      {
        float d = 1.0 - (v - e1) / (1.0 - e1); // distance to e1 in [0, 1]
        return v * d * d * d;                  // quick turn to 0
      }
      else if (v < e0)
      {
        float d = 1.0 - (e0 - v) / e0;        // distance to e2 in [0, 1];
        return v * d * d * d * d * d;         // quick turn to 0
      }
      return v;
    }

    uniform vec2 view_size;
    uniform float time;
    out vec4 color;
    void main()
    {
      // p in [0.0, 1.0]
      vec2 p =  gl_FragCoord.xy / view_size.xy;

      // time = temps en [s]
      float t = time / 5;

      // zoom
      vec3 f = 4 * 6.28 * vec3(2, 1.8, 1.7) * (1.0 + sin(t/8));

      // warp effect
      float amp_scale = 0.01 * (1.0 + sin(t)) * 96 / f.x;
      vec2 amp = vec2(amp_scale, amp_scale * view_size.x/view_size.y);
      float px = p.x;
      p.x = p.x * (1-amp.x) +
     (amp.x * 0.5 * (1.0 + sin(p.y * f.x * 0.3 * (1.0 + sin(t*10*sin(t/10))))));
      p.y = p.y * (1-amp.y) +
     (amp.y* 0.5 * (1.0 + sin(px  * f.x * 0.3 * (1.0 + sin(t*10*sin(t/10))))));

      // translation in xyz
      vec2 a = vec2(sin(t/2), sin(t/1.5));

      // translation in rgb
      vec3 d = vec3(sin(t/5), sin(t/5.5), sin(t/6));
      float r = sin(f.x * (d.r + a.x + p.x)) * sin(f.x * (d.r + a.y + p.y));
      float g = sin(f.y * (d.g + a.x + p.x)) * sin(f.y * (d.g + a.y + p.y));
      float b = sin(f.z * (d.b + a.x + p.x)) * sin(f.z * (d.b + a.y + p.y));

      // normalize [-1, 1] to [0, 1]
      r = 0.5 * (r + 1.0);
      g = 0.5 * (g + 1.0);
      b = 0.5 * (b + 1.0);

      // contour
      float e0 = 0.7 * (2.0 + sin(p.x + a.x)) / 3.0;
      float e1 = 0.2 + 0.8 * (2.0 + sin(p.y + a.y * 0.5)) / 3.0;
      r = smoothcut(e0, e1, r);
      g = smoothcut(e0, e1, g);
      b = smoothcut(e0, e1, b);

      // fuse colors
      float sum = r + g + b;
      color=vec4(sum * vec3(r, g, b), 1.0);
    }"
  ]

let effect = Effect.create program
let op = Renderer.op effect (fullscreen ())

(* Render *)

let render r _ =
  Effect.set_uniform op.effect time (Time.elapsed ());
  Renderer.add_op r op;
  Renderer.render r;
  Surface.update ();
  ()

(* Setup *)

let setup size =
  let s = S.value size in
  let r = Renderer.create ~size:s (module Lit_gl : Lit.Renderer.T) in
  let resize = S.l1 (Renderer.set_size r) size in
  let draw = E.map (render r) Surface.refresh in
  App.sink_signal resize;
  App.sink_event draw;
  Surface.steady_refresh ~until:E.never;
  r

let main () =
  let hidpi = App.env "HIDPI" ~default:true bool_of_string in
  let size = Size2.v 600. 400. in
  let surface = Surface.create ~hidpi ~size () in
  let mode_set = Surface.mode_flip (Key.up `Space) in
  Surface.set_mode_setter mode_set;
  match App.init ~surface () with
  | Error (`Msg e) -> Printf.eprintf "%s" e; exit 1
  | Ok () ->
      let r = setup Surface.raster_size in
      App.run ~until:App.quit ();
      Renderer.release r;
      exit 0

let () = main ()

(*---------------------------------------------------------------------------
   Copyright (c) 2014 Daniel C. Bünzli.
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
