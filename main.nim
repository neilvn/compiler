import std/os

import lexer

proc main() =
    echo "Teeny Tiny Compiler"

    let args = commandLineParams()

    if args.len != 2:
        quit("Incorrect number of arguments")

    let source = readFile(args[1])

    var mylexer = lexer.initLexer(source)
