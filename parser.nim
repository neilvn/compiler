import std/os

from lexer import Lexer

from tokens import TokenType

type Parser = object
    curr_token = ""
    peek_token = ""
    
proc initParser(self: Parser, lexer: Lexer): Parser =
    let x = "hi"

proc check_token(self: Parser, kind: TokenType): bool =
    return $kind == self.curr_token

proc check_peek(self: Parser, kind: TokenType): bool =
    return $kind == self.peek_token
