## 0.2.0

- Add mirage layer and influxdb reporter (#28, @hannesm)
- Gnuplot: namespacing improvements (#34, @CraigFe)
- Gnuplot: optional graph generation (#35, @CraigFe)
- Support OCaml 4.08 (#37, @CraigFe)
- Use OCamlFormat 0.14.1 (#38, #45, @CraigFe and @samoht)
- opam: remove the 'build' directive on dune dependency (#43, @CraigFe)
- introduce Metrics.cache_reporter -- a reporter holding the most recent
  measurement from each reporting sources (#42, @hannesm)
- Influx: expose the "encode_line_protocol" function (#42, @hannesm)
- Metrics_lwt: provide a source based on Logs.warn_count and
  Logs.error_count (#42, @hannesm)
- Metrics_lwt: provide a function to periodically poll a source
  (used e.g. for GC stats etc.) (#42, @hannesm)
- Mirage: fix the mirage subpackage for newer mirage APIs (#42, @hannesm)

## 0.1.0

Initial version
