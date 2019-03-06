Vecosek: The Very Controllable Sequencer
========================================

Vecosek is a MIDI sequencer designed live performance settings, with arbitrarily
*complex* music.

- A **“scene”** is a collection of (looping) tracks and event-handlers, both
  trigger different kinds of “actions” (directly outputting MIDI events *or*
  controlling the sequencer).
- Scenes are described in a JSON format (or its equivalent
  [Biniou](https://github.com/mjambon/biniou) for performance), and are meant to
  be constructed with an EDSL (we provide an OCaml library:
  [`vecosek-scene`](https://smondet.gitlab.io/vecosek/master/vecosek-scene/index.html),
  see the module
  [`Vecosek_scene.Scene`](https://smondet.gitlab.io/vecosek/master/vecosek-scene/Vecosek_scene/Scene/index.html)).

It does not have a graphical user interface; but you can nicely use it together
with [Vimebac](https://gitlab.com/smondet/vimebac).

Vecosek is an experimental successor to the venerable
[Locoseq](https://github.com/smondet/locoseq).


Build
-----

You may consult the `.gitlab-ci.yml` file (and then the `*.opam` files) for
dependencies and build-instructions, locally, it should be as simple as:

    ocaml please.ml configure
    jbuilder build @install

and see:

    _build/default/src/app/main.exe --help

To build the documentation:

    sh tools/build-doc.sh


Tests
-----

See `src/test/scenes.ml` for a few test-scenes, you can build them with:

    jbuilder build _build/default/src/test/scenes.exe

And then see:

    _build/default/src/test/scenes.exe --help
