Build and test
--------------


    topkg build
    ./odig-dev CMD  # This uses a cache in /tmp/odig-cache


Runs of `odig-dev` default to `info` verbosity and automatically
generate a trace in `/tmp/odig-cache/trace.json`.

Publish sample to gh-pages
--------------------------

```
cd sample
./setup.sh
./gen.sh
cd ..
topkg run publish
```

Working on themes
-----------------

An easy way is to generate a representative docset and then:

    rm -r $(opam var share)/odig/odoc-theme
    ln -s $(pwd)/themes $(opam var share)/odig/odoc-theme



