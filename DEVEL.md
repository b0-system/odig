This project uses (perhaps the development version of) [`b0`] for
development. Consult [b0 occasionally] for quick hints on how to
perform common development tasks.

[`b0`]: https://erratique.ch/software/b0
[b0 occasionally]: https://erratique.ch/software/b0/doc/occasionally.html


Build and test
--------------

    source dev-env
    topkg build   # or brzo -b
    odig          # Uses a cache in /tmp/odig-cache

Publish sample to gh-pages
--------------------------

```
cd sample
./setup.sh
eval $(opam env)
./gen.sh
cd ..
topkg run publish
```

Working on themes
-----------------

An easy way is to generate a representative docset and then:

    mkdir -p $(opam var share)/odig.dev
    ln -s $(pwd)/themes $(opam var share)/odig.dev/odoc-theme



