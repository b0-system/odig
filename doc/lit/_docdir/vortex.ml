(*---------------------------------------------------------------------------
   Copyright (c) 2014 Daniel C. Bünzli. All rights reserved.
   Distributed under the ISC license, see terms at the end of the file.
   lit v0.0.0-126-g4058b8a
  ---------------------------------------------------------------------------*)

(* Animated vortex.

   Pixel shader due to http://badc0de.jiggawatt.org
   Used with permission.

   Compile with
   ocamlfind ocamlopt -package tgls.tgl3,lit.gl,useri.tsdl,useri -linkpkg \
      vortex.ml -o vortex.native *)

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
    Ba.set_3d b 0 0 1 2;                           (* triangles *)
    Ba.set_3d b 3 2 1 3;
    Buf.create (`UInt8 b)
  in
  Prim.create ~index `Triangles attrs

let time = Uniform.float "time" 0.
let program =
  let uset = Uniform.(empty + viewport_size "view_size" + time) in
  Prog.create ~uset [
    Prog.shader `Vertex "
    in vec3 vertex;
    void main() { gl_Position = vec4(vertex, 1.0); }";
    Prog.shader `Fragment "
    uniform vec2 view_size;
    uniform float time;
    out vec4 color;
    void main()
    {
      float time = 2 * time;
      vec2 p = -1.0 + 2.0 * gl_FragCoord.xy / view_size.xy;
      float a = time*40.0;
      float d,e,f,g=1.0/40.0,h,i,r,q;
      e=400.0*(p.x*0.5+0.5);
      f=400.0*(p.y*0.5+0.5);
      i=200.0+sin(e*g+a/150.0)*20.0;
      d=200.0+cos(f*g/2.0)*18.0+cos(e*g)*7.0;
      r=sqrt(pow(i-e,2.0)+pow(d-f,2.0));
      q=f/r;
      e=(r*cos(q))-a/2.0;f=(r*sin(q))-a/2.0;
      d=sin(e*g)*176.0+sin(e*g)*164.0+r;
      h=((f+d)+a/2.0)*g;
      i=cos(h+r*p.x/1.3)*(e+e+a)+cos(q*g*6.0)*(r+h/3.0);
      h=sin(f*g)*144.0-sin(e*g)*212.0*p.x;
      h=(h+(f-e)*q+sin(r-(a+h)/7.0)*10.0+i/4.0)*g;
      i+=cos(h*2.3*sin(a/350.0-q))*184.0*sin(q-(r*4.3+a/12.0)*g)+tan(r*g+h)*
         184.0*cos(r*g+h);
      i=mod(i/5.6,256.0)/64.0;
      if(i<0.0) i+=4.0;
      if(i>=2.0) i=4.0-i;
      d=r/350.0;
      d+=sin(d*d*8.0)*0.52;
      f=(sin(a*g)+1.0)/2.0;
      color=vec4(vec3(f*i/1.6,i/2.0+d/13.0,i)*d*p.x+
            vec3(i/1.3+d/8.0,i/2.0+d/18.0,i)*d*(1.0-p.x),1.0);
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
  App.sink_event draw;
  App.sink_signal resize;
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
   Copyright (c) 2014 Daniel C. Bünzli

   Permission to use, copy, modify, and/or distribute this software for any
   purpose with or without fee is hereby granted, provided that the above
   copyright notice and this permission notice appear in all copies.

   THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
   WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
   MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
   ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
   WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
   ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
   OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
  ---------------------------------------------------------------------------*)
