# VM translator

[![Build Status](https://travis-ci.org/computationclub/vm-translator.svg?branch=master)](https://travis-ci.org/computationclub/vm-translator)

This is a Ruby implementation of a translator from VM code to Hack assembly language. The source VM language and the design of this translator are described in [chapter seven](http://nand2tetris.org/lectures/PDF/lecture%2007%20virtual%20machine%20I.pdf) of “[The Elements of Computing Systems](http://nand2tetris.org/)”, and the target assembly language is described in [chapter four](http://nand2tetris.org/chapters/chapter%2004.pdf).

## Running

The translator is at `bin/translator`. It reads a VM program from the file named in its first argument (or from standard input if no argument is provided); in slight defiance of the book, it then writes a Hack assembly version of that program to standard output rather than directly to a file.

For example:

```
$ git clone https://github.com/computationclub/vm-translator
$ cd vm-translator
$ ./bin/translator spec/acceptance/examples/SimpleAdd.vm
@7
D=A
@SP
A=M
M=D
@SP
M=M+1
@8
D=A
@SP
A=M
M=D
@SP
M=M+1
@SP
AM=M-1
D=M
A=A-1
M=M+D
```

## Testing

Most of the tests depend upon the CPU emulator provided as part of the [Nand2Tetris Software Suite](http://nand2tetris.org/software.php). Before running the tests, download and unzip [nand2tetris.zip](http://nand2tetris.org/software/nand2tetris.zip) and set the environment variable `EMULATOR` to the path of the `nand2tetris/tools/CPUEmulator.sh` script.

Both unit and acceptance tests are provided.

The unit tests verify that each module (`Parser` and `CodeWriter`) implements the API described in chapter seven. To run them, use `bundle exec rspec spec/unit`.

The acceptance tests run `bin/translator` against each [example VM program](spec/acceptance/examples) and check the emulated behaviour of its output. To run them, use `bundle exec rspec spec/acceptance`.

To run all of the tests, use `bundle exec rspec`.
