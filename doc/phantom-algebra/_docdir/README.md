# Phantom-algebra — a strongly-typed tensor library à la GLSL

Phantom-algebra is a pure OCaml library implementing strongly-typed
small tensors with dimensions 0 ≤ 4, rank ≤ 2, and limited to square matrices.

It makes it possible to manipulate vector and matrix expressions with an
uniform notation while still catching non-sensical operations at compile time

# Tutorial

For instance, this extract is valid
```OCaml
    open Phantom_algebra.Core
    let v = vec3 1. 2. 3.
    let w = vec3 3. 2. 1.
    let u = scalar 2. + cross (v + w) (v - w)
    let rot = rotation u v 1.
    let r = w + rot * v
```

but adding a vector to a matrix is not, and yields a type error:

```OCaml
v + rot
```
>  `` Type 'b two = [ `two of 'b ]
>  is not compatible with type
>  [< `one of … | `zero of … ] as 'c ``

Type errors tend to be quite long to say the least, but individual type
of scalars, vectors and matrices are much simpler. However, the size of the
type of higher order function may increase exponentially due to the exotic
type construction used internally.

`Phantom-algebra` is inspired by GLSL conventions:

  * addition is the usual vector addition, with scalar broadcasted
    to tensors of any dimension and rank

``` OCaml
    let v = vec2 0. 1. + scalar 1. (* = (1. 2.) *)
```

  * `x * y` is interpreted as:
    * the external product if either `x` or `y` is a scalar
    * the matrix product if either `x` or `y` is a matrix
    * the component-wise (Hadamard) product otherwise
      (if both `x` and `y` are a vector)


  * the cross-product of two 2d vectors yields a scalar whereas
    the cross-product of two 3d vectors yields a 3d pseudo-vectors.
    (other cross-product are type errors), for instance

    ```OCaml
      cross (vec2 1. 1.) (vec2 (-1.) 1.) + vec4 1 0. 0. 0. = vec4 3. 2. 2. 2.
     ```

  * Indices are also-strongly typed, trying to access a index beyond the
    tensor dimension yields a type error.
    ```OCaml
    let v = vec2 2. 3.
    let fine = v.%(x')
    let wrong = v.%(z')
    let m = mat2 v v
    let fine = m.%(xy')
    let also_wrong = m.%(zx')
    let wrong_rank_this_time = m.%(x')
    ```

    * Index names follows GLSL convention with a `'` suffix to avoid shadowing:
    either `x'`, `y'`, `z'` and `w'`, `r', `g'`, `b'`, `a'`
    or `s'`, `t'`, `p'` and `q'`.

  * Similarly, slicing a rank `k` tensor with a rank `n` index
    yields a rank `k-n` tensor of the same dimension, e.g
    ```OCaml
    let e1 = (vec2 1. 0.)
    let id = mat2  e1 (vec2 0. 1.)
    let e1' = id.%[x'] (* this is the first row of the id matrix *)
    let zero = id.%[xy']
    ```

  * Swizzling is supported: `dim` indices can be combined with the `&` operator
    to yield an objet of `r+1` rank:

    ```OCaml
     let v = vec4 0. 1. 2. 3.
     let w = v.%[w'&z'&'y&'x] (* slicing a vector yields a scalar,
     and 4 scalars grouped together become a vector *)
     ;; w = vec4 3. 2. 1. 0.
     let mat = eye d2
     let s = mat.%[y'&x']
     (* we are reversing the rows, and obtaining a new matrix*)
     ;; s = mat2 (vec2 0. 1.) (vec2 1. 0.)
     ```

  * the scalar product and usual norm are supported:

   ```OCaml
     norm2 v = (v|*|v)
   ```

  * Usual mathematics functions have been extended to operates
    element-wise on tensor, they are able in the `Math` module

   ```OCaml
      let v = Math.cos (vec2 1. 2.)
   ```

   * Some usual matrix and vector functions are predefined

   ```OCaml
       let id = eye d2
       let rxy t = rotation (vec3 1. 0. 0.) (vec3 0. 1. 0.) t
       let id = diag (vec3 1. 1. 1.)
   ```

   * The exponential function on matrices is the matrix exponentiation

   ```OCaml
    ;; exp (mat2 (0. 1.) (0. -1) ) = rxy 1.
   ```


   * Vectors can be concatened and stretched to a given dimension

   ```OCaml
   let v = scalar 0. |+| vec2 1. 0. |+| scalar 1.
   let w = vec4' (scalar 1.)
   ```