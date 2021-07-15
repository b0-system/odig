The distribution contains generated data. If you want to contribute
please hack your way directly via the source repository.

For developing, you will need to install [uucd][uucd] and download a copy
of the XML Unicode character database to `support/ucd.xml` (this will be done
automatically if the file doesn't exist). From the root directory of the
repository type:

    ocaml ./pkg/build_support.ml

The result is in the file `src/uunf_data.ml`. It contains the data
extracted from the Unicode character database needed to implement the
normalization forms. This file is ignored by git.

For the `topkg test` to work download the `NormalizationTest.txt` file
to the `test` directory this can simply done by:

    ocaml ./pkg/get_tests.ml
    topkg build
    topkg test
 
[uucd]: http://erratique.ch/software/uucd
