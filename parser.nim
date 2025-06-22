import std/options
import std/os

from lexer import get_token, Lexer, Token
from tokens import TokenType

type Parser = object
    curr_token: Token
    peek_token: Token
    lexer: Lexer
    
proc next_token(self: var Parser) =
    self.curr_token = self.peek_token
    self.peek_token = self.lexer.get_token().get()


proc initParser(lexer: Lexer): Parser =
    var parser = Parser(lexer: lexer)
    parser.next_token()
    parser.next_token()
    return parser


proc check_token(self: var Parser, token: Token): bool {.inline.} =
    return token.kind == self.curr_token.kind


proc check_peek(self: Parser, token: Token): bool {.inline.}  =
    return token.kind == self.peek_token.kind


proc match(self: var Parser, token: Token) =
    if not self.check_token(token):
        quit("Expected" & $token.kind & ", got " & $self.curr_token) 
    self.next_token()


proc program(self: var Parser) =
    let token = Token(text: "", kind: TokenType.EOF)
    while not self.check_token(token):
        self.statement()


proc statement(self: var Parser) =
    if self.check_token(Token(text: "", kind: TokenType.PRINT)):
        echo "STATEMENT-PRINT"
        self.next_token()

        if self.check_token(Token(text: "", kind: TokenType.STRING)):
            self.next_token()
        else:
            self.expression()
    self.nl()
