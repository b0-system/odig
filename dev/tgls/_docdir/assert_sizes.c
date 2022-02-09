/*---------------------------------------------------------------------------
   Copyright (c) 2013 Daniel C. Bünzli. All rights reserved.
   Distributed under the ISC license, see terms at the end of the file.
   tgls v0.8.5
  ---------------------------------------------------------------------------*/

/* Compile with:
   gcc -o assert_sizes assert_sizes.c

   The following assertions should hold to be sure that the bindings
   work correctly. */

#include <assert.h>
#include <stddef.h>

int main (void)
{

  assert (sizeof (int) == 4);
  assert (sizeof (unsigned int) == 4);

  if (sizeof (void *) == 4)
    {
      assert (sizeof (ptrdiff_t) == 4);
    }
  else if (sizeof (void *) == 8)
    {
      assert (sizeof (ptrdiff_t) == 8);
    }
  else
    {
      assert (0);
    }
  return 0;
}


/*---------------------------------------------------------------------------
   Copyright (c) 2013 Daniel C. Bünzli

   Permission to use, copy, modify, and/or distribute this software for any
   purpose with or without fee is hereby granted, provided that the above
   copyright notice and this permission notice appear in all copies.

   THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
   WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
   MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
   ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
   WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
   ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
   OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
  ---------------------------------------------------------------------------*/