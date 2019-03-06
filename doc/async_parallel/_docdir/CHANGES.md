## 113.33.00

- Add an option `~close_stdout_and_stderr` to `Async_parallel_deprecated.Std.Parallel.init`
  to close the `stdout` & `stderr` fds.

  This is needed when using `Async_parallel_deprecated` in a daemonized processes, such as
  the in-development jenga server.

  Without this option, Calling ` Process.run ~prog:"jenga" ~args:`"server";"start"` ` from
  build-manager is problematic because the resulting deferred never becomes determined.

## 113.24.00

- Switched to ppx.

## 112.35.00

- Renamed `Async_parallel` as `Async_parallel_deprecated`; one should
  use `Rpc_parallel` instead.

## 112.17.00

- Modernize the code

## 111.25.00

- improve error handling

## 109.41.00

Rename library from Parallel to Async_parallel

