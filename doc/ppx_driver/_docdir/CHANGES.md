## v0.9.1

- Add support for lint passes

- Add the following command line options
  + `-as-pp` and `--as-pp`
  + `-cookie` and `--cookie <name>=<expr>`

- change the default behavior regarding embedding of errors: now the
  user has to explicitely pass `-dump-ast -embed-errors` or use
  `-as-pp`

## v0.9.0

No changelog available

## 113.43.00

- Update for the new context free API

## 113.24.00

- Disable safety check when code transformations are used as standard
  "-ppx" rewriters.

- Introduce reserved namespaces, see `Ppx_core`'s changelog.

  Pass errors as attribute with -dparsetree to avoid
  "Error while running external preprocessor".

- Update to follow `Ppx_core` evolution.
