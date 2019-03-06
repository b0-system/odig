## 0.5.0 (2018-03-25)

- Remove dependency on lwt_log use logs_lwt instead to ensure compatibility with  >= lwt 3.1.0 see #2. 
- Remove usage of Lwt.ignore_result see #3.
- Ensure that on node start up if using a remote config then any remote nodes are connected to first before proceeding. Failure
  to connected to any remote node in the config will cause the node to not start.
- Move to using Jbuilder (using topkg jbuilder integration as well) instead of Oasis. The library will now appear as two
  packages on opam : distributed (the concurrent I/O agnostic core) and distributed-lwt the lwt based implementation.
- Moved to using odoc to generate documentation.
- Stopped using oUnit for unit tests.
- Ensure compatibility with lwt >= 4.0.0 (safe semantics) #3.
- Ensure pids are unique across functor invocations.
- Simplify library : remove heartbeat functionality, can be duplicated at application level using receive time-outs and spawning
  corresponding process on remote node.
- Update case/receive API so that calling receive/receive_loop with a list of empty matchers is a compile time error.
  New APIs are `val case : (message_type -> (unit -> 'a t) option) -> 'a matcher_list`, `termination_case : (monitor_reason -> 'a t) -> 'a matcher_list`, `val (|.) : 'a matcher_list -> 'a matcher_list -> 'a matcher_list`, `val receive : ?timeout_duration:float -> 'a matcher_list -> 'a option t`, `val receive_loop : ?timeout_duration:float -> bool matcher_list -> unit t`.
- Added appveyor CI support.
- Added uwt support.

### 0.4.0 (2017-01-18)

- Distributed 0.4.0 is Lwt 3.0.0 compatible see #1.
- Changed the signature of `case` function from `val case : (message_type -> bool) -> (message_type -> 'a t) -> 'a matcher` to `val case : (message_type -> (unit -> 'a t) option) -> 'a matcher` to remove unnecessary asserts.
- Added more unit tests to increase code coverage, integrated with coveralls in build process to get automatic coverage reports.
- bug fixes related to heart beat monitoring.

### 0.3.0 (2016-11-06)

- Removed dependency on batteries to allow compatibility with more versions of ocaml.
- Added receive_loop auxiliary function.
- Added optional monitor remote node function to run_node.
- Modified signature of spawn and run node slightly to take a function (unit -> unit t) instead of unit t.
- Made add_remote_node idempotent when adding a node that already exists.
- Added more examples.
- Added online docs.
- Fix bug related to not cleaning up mailbox in case of exception in user provider message handler or recursive call in user provided handler.
- Fix bug related heart beat processing.

### 0.2.0 (2016-10-25)

- No functional changes over the previous release, just changes related to opam packaging.

### 0.1.0 (2016-10-23)

- Initial release.