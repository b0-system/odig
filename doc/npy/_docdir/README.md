# npy-ocaml
This contains a simple implementation of version 1.0 of the [npy format spec](http://docs.scipy.org/doc/numpy-dev/neps/npy-format.html). An opam package is available and can be installed via:

```bash
opam install npy
```

The main functions are:
* Writing ocaml bigarrays to npy files, these files can then be loaded from python using numpy.load.
* Reading ocaml bigarrays from npy files, the resulting bigarrays are mmapped to the file.
* Reading and writing npz files that could contain multiple arrays.
