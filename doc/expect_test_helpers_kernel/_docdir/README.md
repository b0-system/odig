January 2017

`Expect_test_helpers_kernel` is a library intended for use with expect
tests, i.e. the `let%expect_test` syntax.  It has functions that are
generally useful in writing expect tests, and are aimed at printing
output to appear in `[%expect]` expressions.  Widely used functions
include: `print_s`, `require`, and `show_raise`.

`Expect_test_helpers_kernel` depends on `Core_kernel` and does not use
Unix or Async.  It is suitable for use in JavaScript.  Also see the
`Expect_test_helpers` library, which extends
`Expect_test_helpers_kernel` to work in Async and with additional
helper functions that make use of Unix processes.
