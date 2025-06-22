# Lexer

import std/enumutils
import std/options
import std/re
import std/sequtils
import std/strutils
import std/sugar

from tokens import TokenType

type Token* = object
    text*: string
    kind*: TokenType


type Lexer* = object
    source*: string = ""
    curr_char: char = '\t'
    curr_pos: int = -1


proc initLexer*(source: string): Lexer =
    let new_source = source & '\n'
    return Lexer(source: new_source)


proc next_char(self: var Lexer) =
    self.curr_pos += 1
    if self.curr_pos >= self.source.len:
        self.curr_char = '\0'
    else:
        self.curr_char = self.source[self.curr_pos]


proc peek(self: Lexer): char =
    if self.curr_pos + 1 >= self.source.len:
        return '\0'
    return self.source[self.curr_pos + 1]


proc skip_whitespace(self: var Lexer) =
    while self.curr_char in {' ', '\t', '\r'}:
        self.next_char()


proc skip_comment(self: var Lexer) =
    if self.curr_char == '#':
        while self.curr_char != '\n':
            self.next_char()


proc check_if_keyword(self: Lexer, token_text: string): Option[TokenType] =
    for kind in TokenType.toSeq:
        if $kind == token_text and ord(kind) >= 100 and ord(kind) < 200:
            return some(kind)
    return none(TokenType)


proc get_token*(self: var Lexer): Option[Token] =
    self.skip_whitespace()
    self.skip_comment()

    var token: Option[Token] = none(Token)

    if self.curr_char == '+':
        token = some(Token(text: $self.curr_char, kind: TokenType.PLUS))
    elif self.curr_char == '-':
        token = some(Token(text: $self.curr_char, kind: TokenType.MINUS))
    elif self.curr_char == '*':
        token = some(Token(text: $self.curr_char, kind: TokenType.ASTERISK))
    elif self.curr_char == '/':
        token = some(Token(text: $self.curr_char, kind: TokenType.SLASH))
    elif self.curr_char == '\n':
        token = some(Token(text: $self.curr_char, kind: TokenType.NEWLINE))
    elif self.curr_char == '\0':
        token = some(Token(text: $self.curr_char, kind: TokenType.EOF))
    elif self.curr_char == '=':
        if self.peek() == '=':
            let last_char = self.curr_char
            self.next_char()
            token = some(Token(text: $last_char & $self.curr_char, kind: TokenType.EQEQ))
        else:
            token = some(Token(text: $self.curr_char, kind: TokenType.EQ))
    elif self.curr_char == '>':
        if self.peek() == '=':
            let last_char = self.curr_char
            self.next_char()
            token = some(Token(text: $last_char & $self.curr_char, kind: TokenType.GTEQ))
        else:
            token = some(Token(text: $self.curr_char, kind: TokenType.GT))
    elif self.curr_char == '<':
        if self.peek() == '=':
            let last_char = self.curr_char
            self.next_char()
            token = some(Token(text: $last_char & $self.curr_char, kind: TokenType.LTEQ))
        else:
            token = some(Token(text: $self.curr_char, kind: TokenType.LT))
    elif self.curr_char == '!':
        if self.peek() == '=':
            let last_char = self.curr_char
            self.next_char()
            token = some(Token(text: $last_char & $self.curr_char, kind: TokenType.NOTEQ))
        else:
            quit("Expected !=, got !" & self.peek())
    elif self.curr_char.isDigit:
        let start_pos = self.curr_pos
        while self.peek().isDigit:
            self.next_char()
        if self.peek() == '.':
            self.next_char()
            if not self.peek().isDigit:
                quit("Illegal character in number" & $self.peek())
            while self.peek().isDigit:
                self.next_char()

        let token_text = self.source[start_pos..self.curr_pos]
        token = some(Token(text: token_text, kind: TokenType.NUMBER))
    elif self.curr_char.isAlphaAscii:
        let start_pos = self.curr_pos
        while self.peek().isAlphaNumeric:
            self.next_char()
        let token_text = self.source[start_pos..self.curr_pos]
        let keyword_opt = self.check_if_keyword(token_text)

        if keyword_opt.isNone:
            token = some(Token(text: token_text, kind: TokenType.IDENT))
        elif keyword_opt.isSome:
            token = some(Token(text: token_text, kind: keyword_opt.get()))

    self.next_char()
    return token
