# OCaml-Swagger

## Introduction

OCaml-Swagger is a code generator that implements
[Swagger 2.0](https://github.com/OAI/OpenAPI-Specification/blob/master/versions/2.0.md)
API clients in OCaml.

The motivation for this project was the development of a
[Kubernetes API](https://kubernetes.io/docs/reference/)
client, which can be found in the
[Kubecaml](https://github.com/andrenth/kubecaml)
project.

Therefore, while the Kubernetes API is quite large and uses many of Swagger's
features, this library doesn't currently support all of them. Remaining features
will be implemented if needed to support the Kubernetes API, though of course
contributions are welcome.

## Installation

OCaml-Swagger is available on opam:

```sh
$ opam install swagger
```

## Usage

Most users will probably only need to use the `Swagger.codegen` function to
parse an API specification and generate the OCaml code:

```ocaml
let () =
  Swagger.codegen
    ~input:Sys.argv.(1)
    ~output:stdout
    ~path_base:"/"
    ~definition_base:"io.k8s."
    ~reference_base:"#/definitions/io.k8s."
    ~reference_root:"Definitions"
```

This call instructs OCaml-Swagger to read the API specification from the file
name given in the first command-line argument and output the resulting code to
the standard output.

The remaining arguments are prefixes that are stripped from the API definitions
when generating module names. For example, in the Kubernetes API, the
[Definitions Object](https://github.com/OAI/OpenAPI-Specification/blob/master/versions/2.0.md#definitionsObject)s
are named using a reverse-domain name convention, as in
`io.k8s.api.apps.v1.DaemonSet`. Given the `definition_base` above, the
corresponding OCaml module would be `Api.Apps.V1.Daemon_set`, that is, the
`io.k8s` prefix is ignored in the OCaml module structure.

Similarly, references to definitions are specified in the Kubernetes API as
`"$ref": "#/definitions/io.k8s.api.apps.v1.DaemonSet"`. The `reference_base`
parameter allows a prefix to be ignored in
[Reference Object](https://github.com/OAI/OpenAPI-Specification/blob/master/versions/2.0.md#referenceObject)s.

Finally, the `reference_root` parameter specifies the submodule in which the
code for Definition Objects will be created.

## The generated code

Since Swagger APIs may contain reference cycles, OCaml-Swagger uses the
[recursive modules trick](https://blog.janestreet.com/a-trick-recursive-modules-from-recursive-signatures/)
to work around the OCaml restriction that forces one to only reference types or
values that have been previously defined. The wrapper recursive module that
acts as a namespace will have its named derived from the API's
[Info Object](https://github.com/OAI/OpenAPI-Specification/blob/master/versions/2.0.md#infoObject)'s
`title` field.

Inside this module, a module structure mirroring the URI structure of
definitions and operations defined in the Swagger specification will be created.

The code for Definitions defines a type `t` for the definition, a `create`
function taking as many arguments as necessary to create it, and one accessor
function for each definition property.

Operation modules have one function per HTTP operation defined in the API
specification, named after the HTTP verb, in lowercase (i.e., `get`, `put`,
`post`, `delete`, `patch` and `options`), each taking a number of parameters
according to the operations' definition. Operations also take an extra
parameter, an `Uri.t` (from [OCaml-URI](https://github.com/mirage/ocaml-uri)),
used to connect to the API server. In principle, this URI should only contain
the host and port of the API server, as path and query string parameters will
be appended automatically as needed by the operation functions themselves.

With regard to path templating (i.e. replaceable sections of an URL marked with
a path variable name inside curly braces), OCaml-Swagger will create a submodule
in the form `By_{variable_name}` for the templated path. To give a concrete
example, the path template `/api/v1/namespaces/{name}`, present in the
Kubernetes API, will create a module structure such as below.

```ocaml
...
module Namespaces = struct
  ...
  module By_name = struct
    let get ~name ... =
      ...
  end
  ...
end
...
```

Finally, OCaml-Swagger tries to define modules and functions using OCamlish
name conventions. Namely, modules are defined in `Capitalized_snake_case` style
and functions in `lower_snake_case` style, whenever possible.
