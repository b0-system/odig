---
title: ppx_js_style - Enforce Jane Street coding styles
parent: ../README.md
---

ppx\_js\_style is an identity ppx rewriter that enforces Jane Street
coding styles.

Coding rules
------------

The following rules are enforced by ppx\_js\_style:

- `[@@deprecated]` attributes must contain the date of deprecation,
  using the format `"[since MM-YYYY] ..."`

- Enabled by -annotated-ignores:
  Ignored expressions must come with a type annotation, such as:
    `ignore (expr : typ)`
    `let _ : type = expr`

- Enabled by -check-doc-comments:
  Comments in mli must either be documentation comments or explicitely
  "ignored":
    `(** documentation comment *)`
    `(*_ ignored comment *)`
  Normal `(* comment *)` comments are disallowed.

  This flag additionally enables warning 50, which checks the placement
  of documentation comments.

  Finally, doc comments are checked to be syntactically valid.
