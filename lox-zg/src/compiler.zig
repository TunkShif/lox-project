const std = @import("std");
const Chunk = @import("chunk.zig").Chunk;
const Token = @import("token.zig").Token;
const TokenType = @import("token.zig").TokenType;
const Scanner = @import("scanner.zig").Scanner;

pub fn compile(source: []const u8, chunk: *Chunk) !void {
    _ = chunk;
    _ = source;
}

pub const Parser = struct {
    scanner: *Scanner,
    previous: Token,
    current: Token,
    had_error: bool,
    panic_mode: bool,

    pub fn init(scanner: *Scanner) Parser {
        return Parser{
            .scanner = scanner,
            .previous = undefined,
            .current = undefined,
            .had_error = false,
            .panic_mode = false,
        };
    }

    fn advance(self: *Parser) void {
        self.previous = self.current;
        while (true) {
            self.current = self.scanner.scanToken();
            if (self.current.token_type != .token_error) break;
            self.errorAtCurrent(self.current.lexeme);
        }
    }

    fn consume(self: *Parser, token_type: TokenType, message: []const u8) void {
        if (self.current == token_type) {
            self.advance();
            return;
        }
        self.errorsAtCurrent(message);
    }

    fn errors(self: *Parser, message: []const u8) void {
        self.errorAt(&self.previous, message);
    }

    fn errorsAtCurrent(self: *Parser, message: []const u8) void {
        self.errorAt(&self.current, message);
    }

    fn errorsAt(self: *Parser, token: *Token, message: []const u8) void {
        if (self.panic_mode) return;
        self.panic_mode = true;

        const stderr = std.io.getStdErr().writer();
        stderr.print("[line {d}] Error ", .{token.line}) catch return;
        switch (token.type) {
            .token_eof => stderr.print("at end", .{token.line}) catch return,
            .token_error => {
                // do nothing right now
            },
            else => stderr.print("at '{s}'", .{token.lexeme}),
        }
        stderr.print(": {s}\n", .{message});
        self.had_error = true;
    }
};
