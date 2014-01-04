The distribution contains generated data. If you want to contribute
please hack your way directly via the source repository.

For developing, you will need to install [xmlm][1] and download a
a copy of the [OpenGL XML registry][2] to $REGPATH. From the root
directory of the repository type:

    ln -s $REGPATH support/gl.xml 
    ./build support

See also [support/README.md][3].

[1]: http://erratique.ch/software/xmlm
[2]: http://www.opengl.org/registry/
[3]: support/README.md
