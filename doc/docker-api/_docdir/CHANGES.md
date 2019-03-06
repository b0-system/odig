0.2.1 2018-10-30
----------------

- Handle an undocumented status for `Docker.Container.start`.

0.2 2017-10-15
--------------

- Upgrade to API v1.29.
- New signature of `Container.create`.
- Add functions `Container.wait` and `Container.changes`.
- Handle errors `409 Conflict`.
- New exceptions `Docker.Failure` and `Docker.No_such_container`.
- Rename `Docker.Images` as `Docker.Image` and add the `create`
  function to pull images.
- Documentation improvements.
- New tests `ls` and `ps` and improve the other ones.
- Use [Dune](https://github.com/ocaml/dune) and
  [dune-release](https://github.com/samoht/dune-release).


