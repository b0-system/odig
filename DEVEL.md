Build and test
--------------

```
topkg build
./odig-dev CMD  # This uses a cache in /tmp/odig-cache
```

Runs of `odig-dev` default to info verbosity and automatically
generate a trace in `/tmp/odig-cache/trace.json`.

Publish sample to gh-pages
--------------------------

```
cd ~/sample
./setup.sh
./gen.sh
./publish.sh
```


