const std = @import("std");
const Token = @import("token.zig").Token;
const TokenType = @import("token.zig").TokenType;

const KEYWORDS = std.ComptimeStringMap(TokenType, .{
    .{ "and", .token_and },
    .{ "class", .token_class },
    .{ "def", .token_def },
    .{ "else", .token_else },
    .{ "false", .token_false },
    .{ "for", .token_for },
    .{ "if", .token_if },
    .{ "let", .token_let },
    .{ "nil", .token_nil },
    .{ "or", .token_or },
    .{ "return", .token_return },
    .{ "super", .token_super },
    .{ "this", .token_this },
    .{ "true", .token_true },
    .{ "while", .token_while },
});

fn isDigit(char: u8) bool {
    return char >= '0' and char <= '9';
}

fn isAlpha(char: u8) bool {
    return (char >= 'a' and char <= 'z') or (char >= 'A' and char <= 'Z') or char == '_';
}

pub const Scanner = struct {
    source: []const u8,
    start: usize,
    current: usize,
    line: usize,

    pub fn init() @This() {
        return Scanner{
            .source = undefined,
            .start = 0,
            .current = 0,
            .line = 1,
        };
    }

    pub fn reset(self: *@This(), source: []const u8) void {
        self.source = source;
        self.start = 0;
        self.current = 0;
        self.line = 1;
    }

    pub fn scanToken(self: *@This()) Token {
        self.skipWhitespace();

        self.start = self.current;

        if (self.isAtEnd()) {
            return self.makeToken(.token_eof);
        }

        const ch = self.advance();
        switch (ch) {
            '(' => return self.makeToken(.token_lparen),
            ')' => return self.makeToken(.token_rparen),
            '{' => return self.makeToken(.token_lbrace),
            '}' => return self.makeToken(.token_rbrace),
            ';' => return self.makeToken(.token_semicolon),
            ',' => return self.makeToken(.token_comma),
            '.' => return self.makeToken(.token_dot),
            '-' => return self.makeToken(.token_minus),
            '+' => return self.makeToken(.token_plus),
            '/' => return self.makeToken(.token_slash),
            '*' => return self.makeToken(.token_star),
            '!' => return self.makeToken(if (self.match('=')) .token_bang_equal else .token_bang),
            '=' => return self.makeToken(if (self.match('=')) .token_equal_equal else .token_equal),
            '>' => return self.makeToken(if (self.match('=')) .token_greater_equal else .token_greater),
            '<' => return self.makeToken(if (self.match('=')) .token_less_equal else .token_less),
            '"' => return self.string(),
            '0'...'9' => return self.number(),
            'a'...'z', 'A'...'Z', '_' => return self.identifer(),
            else => return self.errorToken("Unexpected character."),
        }
    }

    fn advance(self: *@This()) u8 {
        self.current += 1;
        return self.source[self.current - 1];
    }

    fn peek(self: *@This()) u8 {
        if (self.isAtEnd()) return 0;
        return self.source[self.current];
    }

    fn peekNext(self: *@This()) u8 {
        if (self.current + 1 >= self.source.len) return 0;
        return self.source[self.current + 1];
    }

    fn skipWhitespace(self: *@This()) void {
        while (true) {
            const ch = self.peek();
            switch (ch) {
                ' ', '\r', '\t' => _ = self.advance(),
                '\n' => {
                    self.line += 1;
                    _ = self.advance();
                },
                '/' => {
                    if (self.peekNext() == '/') {
                        while (self.peek() != '\n' and !self.isAtEnd())
                            _ = self.advance();
                    } else {
                        return;
                    }
                },
                else => return,
            }
        }
    }

    fn match(self: *@This(), expected: u8) bool {
        if (self.isAtEnd()) return false;
        if (self.source[self.current] != expected) return false;
        self.current += 1;
        return true;
    }

    fn isAtEnd(self: *@This()) bool {
        return self.current >= self.source.len;
    }

    fn makeToken(self: *@This(), token_type: TokenType) Token {
        return Token{
            .token_type = token_type,
            .lexeme = self.source[self.start..self.current],
            .line = self.line,
        };
    }

    fn errorToken(self: *@This(), message: []const u8) Token {
        return Token{
            .token_type = TokenType.token_error,
            .lexeme = message,
            .line = self.line,
        };
    }

    fn string(self: *@This()) Token {
        while (self.peek() != '"' and !self.isAtEnd()) {
            if (self.peek() == '\n') self.line += 1;
            _ = self.advance();
        }

        if (self.isAtEnd()) return self.errorToken("Unterminated string.");
        _ = self.advance();

        return self.makeToken(.token_string);
    }

    fn number(self: *@This()) Token {
        while (isDigit(self.peek())) _ = self.advance();

        if (self.peek() == '.' and isDigit(self.peekNext())) {
            _ = self.advance();
            while (isDigit(self.peek())) _ = self.advance();
        }

        return self.makeToken(.token_number);
    }

    fn identifer(self: *@This()) Token {
        while (isAlpha(self.peek()) or isDigit(self.peek())) _ = self.advance();
        const lexeme = self.source[self.start..self.current];
        const token_type = KEYWORDS.get(lexeme) orelse .token_identifier;
        return self.makeToken(token_type);
    }
};

const expect = std.testing.expect;

test "single-char tokens" {
    const source = "() {} ; , . + - * / ! = > <";
    var scanner = Scanner.init(source);
    try expect(scanner.scanToken().token_type == .token_lparen);
    try expect(scanner.scanToken().token_type == .token_rparen);
    try expect(scanner.scanToken().token_type == .token_lbrace);
    try expect(scanner.scanToken().token_type == .token_rbrace);
    try expect(scanner.scanToken().token_type == .token_semicolon);
    try expect(scanner.scanToken().token_type == .token_comma);
    try expect(scanner.scanToken().token_type == .token_dot);
    try expect(scanner.scanToken().token_type == .token_plus);
    try expect(scanner.scanToken().token_type == .token_minus);
    try expect(scanner.scanToken().token_type == .token_star);
    try expect(scanner.scanToken().token_type == .token_slash);
    try expect(scanner.scanToken().token_type == .token_bang);
    try expect(scanner.scanToken().token_type == .token_equal);
    try expect(scanner.scanToken().token_type == .token_greater);
    try expect(scanner.scanToken().token_type == .token_less);
    try expect(scanner.scanToken().token_type == .token_eof);
}

test "two-char tokens" {
    const source = "== >= <= !=";
    var scanner = Scanner.init(source);
    try expect(scanner.scanToken().token_type == .token_equal_equal);
    try expect(scanner.scanToken().token_type == .token_greater_equal);
    try expect(scanner.scanToken().token_type == .token_less_equal);
    try expect(scanner.scanToken().token_type == .token_bang_equal);
    try expect(scanner.scanToken().token_type == .token_eof);
}

test "skip whitespaces" {
    const source = "     ;    ;";
    var scanner = Scanner.init(source);
    try expect(scanner.scanToken().token_type == .token_semicolon);
    try expect(scanner.scanToken().token_type == .token_semicolon);
    try expect(scanner.scanToken().token_type == .token_eof);
}

test "multiline" {
    const source =
        \\+ ;
        \\- ;
        \\* ;
    ;
    var scanner = Scanner.init(source);
    try expect(scanner.scanToken().token_type == .token_plus);
    try expect(scanner.scanToken().token_type == .token_semicolon);
    try expect(scanner.scanToken().token_type == .token_minus);
    try expect(scanner.scanToken().token_type == .token_semicolon);
    try expect(scanner.scanToken().token_type == .token_star);
    try expect(scanner.scanToken().token_type == .token_semicolon);
    try expect(scanner.scanToken().token_type == .token_eof);
}

test "comments" {
    const source =
        \\// hello world
        \\; // test
        \\/ //
    ;
    var scanner = Scanner.init(source);
    try expect(scanner.scanToken().token_type == .token_semicolon);
    try expect(scanner.scanToken().token_type == .token_slash);
    try expect(scanner.scanToken().token_type == .token_eof);
}

test "string" {
    const source =
        \\"hello";
    ;
    var scanner = Scanner.init(source);

    const token = scanner.scanToken();
    try expect(token.token_type == .token_string);
    try expect(std.mem.eql(u8, token.lexeme, "\"hello\""));

    try expect(scanner.scanToken().token_type == .token_semicolon);
    try expect(scanner.scanToken().token_type == .token_eof);
}

test "multiline string" {
    const source =
        \\"hello,
        \\ world";
    ;
    var scanner = Scanner.init(source);

    const token = scanner.scanToken();
    try expect(token.token_type == .token_string);
    try expect(std.mem.eql(u8, token.lexeme, "\"hello,\n world\""));
}

test "unterminated string" {
    const source =
        \\"fix;
    ;

    var scanner = Scanner.init(source);

    const token = scanner.scanToken();
    try expect(token.token_type == .token_error);
    try expect(std.mem.eql(u8, token.lexeme, "Unterminated string."));
}

test "number" {
    const source = "233 233.3 233.";
    var token: Token = undefined;
    var scanner = Scanner.init(source);

    token = scanner.scanToken();
    try expect(token.token_type == .token_number);
    try expect(std.mem.eql(u8, token.lexeme, "233"));

    token = scanner.scanToken();
    try expect(token.token_type == .token_number);
    try expect(std.mem.eql(u8, token.lexeme, "233.3"));

    token = scanner.scanToken();
    try expect(token.token_type == .token_number);
    try expect(std.mem.eql(u8, token.lexeme, "233"));

    try expect(scanner.scanToken().token_type == .token_dot);
}

test "keywords" {
    const source = "and class def else false for if let nil or return super this true while";
    var token: Token = undefined;
    var scanner = Scanner.init(source);

    token = scanner.scanToken();
    try expect(token.token_type == .token_and);
    token = scanner.scanToken();
    try expect(token.token_type == .token_class);
    token = scanner.scanToken();
    try expect(token.token_type == .token_def);
    token = scanner.scanToken();
    try expect(token.token_type == .token_else);
    token = scanner.scanToken();
    try expect(token.token_type == .token_false);
    token = scanner.scanToken();
    try expect(token.token_type == .token_for);
    token = scanner.scanToken();
    try expect(token.token_type == .token_if);
    token = scanner.scanToken();
    try expect(token.token_type == .token_let);
    token = scanner.scanToken();
    try expect(token.token_type == .token_nil);
    token = scanner.scanToken();
    try expect(token.token_type == .token_or);
    token = scanner.scanToken();
    try expect(token.token_type == .token_return);
    token = scanner.scanToken();
    try expect(token.token_type == .token_super);
    token = scanner.scanToken();
    try expect(token.token_type == .token_this);
    token = scanner.scanToken();
    try expect(token.token_type == .token_true);
    token = scanner.scanToken();
    try expect(token.token_type == .token_while);
}

test "identifer" {
    const source = "num;";
    var scanner = Scanner.init(source);

    const token = scanner.scanToken();
    try expect(token.token_type == .token_identifier);
    try expect(std.mem.eql(u8, token.lexeme, "num"));
}
