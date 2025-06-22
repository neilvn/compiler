import std/sets
import std/options

from lexer import get_token, initLexer, Lexer, Token
from tokens import TokenType

type Parser = object
    curr_token: Token
    peek_token: Token
    lexer: Lexer
    symbols: HashSet[string]
    labels_declared: HashSet[string]
    labels_gotoed: HashSet[string]


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
        quit("Expected " & $token.kind & ", got " & $self.curr_token) 
    self.next_token()


proc primary(self: var Parser) =
    echo "PRIMARY (" & $self.curr_token.text & ")"
    if self.check_token(Token(kind: TokenType.NUMBER)):
        self.next_token()
    elif self.check_token(Token( kind: TokenType.IDENT)):
        self.next_token()
    else:
        quit("Unexpected token at: " & self.curr_token.text)


proc unary(self: var Parser) =
    echo "UNARY"
    while self.check_token(Token(kind: TokenType.PLUS)) or self.check_token(Token(kind: TokenType.MINUS)):
        self.next_token()
    self.primary()


proc term(self: var Parser) =
    echo "TERM"
    self.unary()
    while self.check_token(Token(kind: TokenType.ASTERISK)) or self.check_token(Token(kind: TokenType.SLASH)):
        self.next_token()
        self.unary()


proc expression(self: var Parser) =
    echo "EXPRESSION"
    self.term()
    while self.check_token(Token(kind: TokenType.PLUS)) or self.check_token(Token(kind: TokenType.MINUS)):
        self.next_token()
        self.term()


proc is_comparison_operator(self: var Parser): bool =
    return bool(self.check_token(Token(kind: TokenType.GT))) or bool(self.check_token(Token(kind: TokenType.LT))) or bool(self.check_token(Token(kind: TokenType.LTEQ))) or bool(self.check_token(Token(kind: TokenType.GTEQ))) or bool(self.check_token(Token(kind: TokenType.NOTEQ)))


proc comparison(self: var Parser) =
    echo "COMPARISON"
    self.expression()

    if self.is_comparison_operator():
        self.next_token()
        self.expression()
    else:
        quit("Expected comparison operator at: " & self.curr_token.text)

    while self.is_comparison_operator():
        self.next_token()
        self.expression()


proc nl(self: var Parser) =
    echo "NEWLINE"
    self.match(Token(kind: TokenType.NEWLINE))
    while self.check_token(Token(kind: TokenType.NEWLINE)):
        self.next_token()


proc statement(self: var Parser) =
    # "PRINT" (expression | string)
    if self.check_token(Token(kind: TokenType.IF)):
        echo "STATEMENT-PRINT"
        self.next_token()

        if self.check_token(Token(kind: TokenType.IF)):
            # Simple string.
            self.next_token()

        else:
            # Expect an expression.
            self.expression()

    # "IF" comparison "THEN" {statement} "ENDIF"
    elif self.check_token(Token(kind: TokenType.IF)):
        echo "STATEMENT-IF"
        self.next_token()
        self.comparison()

        self.match(Token(kind: TokenType.THEN))
        self.nl()

        # Zero or more statements in the body.
        while not self.check_token(Token(kind: TokenType.ENDIF)):
            self.statement()

        self.match(Token(kind: TokenType.ENDIF))

    # "WHILE" comparison "REPEAT" {statement} "ENDWHILE"
    elif self.check_token(Token(kind: TokenType.WHILE)):
        echo "STATEMENT-WHILE"
        self.next_token()
        self.comparison()

        self.match(Token(kind: TokenType.REPEAT))
        self.nl()

        # Zero or more statements in the loop body.
        while not self.check_token(Token(kind: TokenType.ENDWHILE)):
            self.statement()

        self.match(Token(kind: TokenType.ENDWHILE))

    # "LABEL" ident
    elif self.check_token(Token(kind: TokenType.LABEL)):
        echo "STATEMENT-LABEL"
        self.next_token()

        # Make sure this label doesn't already exist.
        if self.curr_token.text in self.labelsDeclared:
            quit("Label already exists: " & self.curr_token.text)
        self.labels_declared.incl(self.curr_token.text)

        self.match(Token(kind: TokenType.IDENT))

    # "GOTO" ident
    elif self.check_token(Token(kind: TokenType.GOTO)):
        echo "STATEMENT-GOTO"
        self.next_token()
        self.labels_gotoed.incl(self.curr_token.text)
        self.match(Token(kind: TokenType.IDENT))

    # "LET" ident "=" expression
    elif self.check_token(Token(kind: TokenType.LET)):
        echo "STATEMENT-LET"
        self.next_token()

        #  Check if ident exists in symbol table. If not, declare it.
        if self.curr_token.text notin self.symbols:
            self.symbols.incl(self.curr_token.text)

        self.match(Token(kind: TokenType.IDENT))
        self.match(Token(kind: TokenType.EQ))
        
        self.expression()

    # "INPUT" ident
    elif self.check_token(Token(kind: TokenType.INPUT)):
        echo("STATEMENT-INPUT")
        self.next_token()

        # If variable doesn't already exist, declare it.
        if self.curr_token.text notin self.symbols:
            self.symbols.incl(self.curr_token.text)

        self.match(Token(kind: TokenType.IDENT))

    # This is not a valid statement. Error!
    else:
        quit("Invalid statement at " & self.curr_token.text & " (" & $self.curr_token.kind & ")")

    # Newline.
    self.nl()


proc program(self: var Parser) =
    let token = Token(kind: TokenType.EOF)
    while not self.check_token(token):
        self.statement()


proc main() =
    let source = readFile("input.txt")
    let lexer = Lexer(source: source)
    var parser = initParser(lexer)

    parser.program()

main()
