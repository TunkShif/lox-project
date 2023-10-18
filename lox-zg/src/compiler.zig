const std = @import("std");
const debug = @import("debug.zig");
const config = @import("config.zig");
const Allocator = std.mem.Allocator;
const Chunk = @import("chunk.zig").Chunk;
const OpCode = @import("chunk.zig").OpCode;
const Token = @import("token.zig").Token;
const TokenType = @import("token.zig").TokenType;
const Scanner = @import("scanner.zig").Scanner;
const Value = @import("value.zig").Value;
const String = @import("object.zig").String;
const ObjectPool = @import("object.zig").ObjectPool;

const Precedence = enum(u8) {
    prec_none,
    prec_assignment, // =
    prec_or, // or
    prec_and, // and
    prec_equality, // == !=
    prec_comparison, // < > <= >=
    prec_term, // + -
    prec_factor, // * /
    prec_unary, // ! -
    prec_call, // . ()
    prec_primary,
};

const ParseFn = *const fn (compiler: *Compiler) anyerror!void;

const ParseRule = struct {
    prefix: ?ParseFn,
    infix: ?ParseFn,
    precedence: Precedence,

    fn getRule(token_type: TokenType) *const ParseRule {
        return &rules[@intFromEnum(token_type)];
    }
};

const rules = [_]ParseRule{
    .{ .prefix = Compiler.grouping, .infix = null, .precedence = .prec_none }, // token_lparen,
    .{ .prefix = null, .infix = null, .precedence = .prec_none }, // token_rparen,
    .{ .prefix = null, .infix = null, .precedence = .prec_none }, // token_lbrace,
    .{ .prefix = null, .infix = null, .precedence = .prec_none }, // token_rbrace,
    .{ .prefix = null, .infix = null, .precedence = .prec_none }, // token_comma,
    .{ .prefix = null, .infix = null, .precedence = .prec_none }, // token_dot,
    .{ .prefix = Compiler.unary, .infix = Compiler.binary, .precedence = .prec_term }, // token_minus,
    .{ .prefix = null, .infix = Compiler.binary, .precedence = .prec_term }, // token_plus,
    .{ .prefix = null, .infix = null, .precedence = .prec_none }, // token_semicolon,
    .{ .prefix = null, .infix = Compiler.binary, .precedence = .prec_factor }, // token_slash,
    .{ .prefix = null, .infix = Compiler.binary, .precedence = .prec_factor }, // token_star,
    .{ .prefix = Compiler.unary, .infix = null, .precedence = .prec_none }, // token_bang,
    .{ .prefix = null, .infix = Compiler.binary, .precedence = .prec_equality }, // token_bang_equal,
    .{ .prefix = null, .infix = null, .precedence = .prec_none }, // token_equal,
    .{ .prefix = null, .infix = Compiler.binary, .precedence = .prec_equality }, // token_equal_equal,
    .{ .prefix = null, .infix = Compiler.binary, .precedence = .prec_comparison }, // token_greater,
    .{ .prefix = null, .infix = Compiler.binary, .precedence = .prec_comparison }, // token_greater_equal,
    .{ .prefix = null, .infix = Compiler.binary, .precedence = .prec_comparison }, // token_less,
    .{ .prefix = null, .infix = Compiler.binary, .precedence = .prec_comparison }, // token_less_equal,
    .{ .prefix = null, .infix = null, .precedence = .prec_none }, // token_identifier,
    .{ .prefix = Compiler.string, .infix = null, .precedence = .prec_none }, // token_string,
    .{ .prefix = Compiler.number, .infix = null, .precedence = .prec_none }, // token_number,
    .{ .prefix = null, .infix = null, .precedence = .prec_none }, // token_and,
    .{ .prefix = null, .infix = null, .precedence = .prec_none }, // token_class,
    .{ .prefix = null, .infix = null, .precedence = .prec_none }, // token_def,
    .{ .prefix = null, .infix = null, .precedence = .prec_none }, // token_else,
    .{ .prefix = Compiler.literal, .infix = null, .precedence = .prec_none }, // token_false,
    .{ .prefix = null, .infix = null, .precedence = .prec_none }, // token_for,
    .{ .prefix = null, .infix = null, .precedence = .prec_none }, // token_if,
    .{ .prefix = null, .infix = null, .precedence = .prec_none }, // token_let,
    .{ .prefix = Compiler.literal, .infix = null, .precedence = .prec_none }, // token_nil,
    .{ .prefix = null, .infix = null, .precedence = .prec_none }, // token_or,
    .{ .prefix = null, .infix = null, .precedence = .prec_none }, // token_return,
    .{ .prefix = null, .infix = null, .precedence = .prec_none }, // token_super,
    .{ .prefix = null, .infix = null, .precedence = .prec_none }, // token_this,
    .{ .prefix = Compiler.literal, .infix = null, .precedence = .prec_none }, // token_true,
    .{ .prefix = null, .infix = null, .precedence = .prec_none }, // token_while,
    .{ .prefix = null, .infix = null, .precedence = .prec_none }, // token_error,
    .{ .prefix = null, .infix = null, .precedence = .prec_none }, // token_eof,
};

pub const Compiler = struct {
    scanner: Scanner,
    previous: Token,
    current: Token,
    compiling_chunk: *Chunk,
    had_error: bool,
    panic_mode: bool,
    object_pool: *ObjectPool,

    pub fn init(object_pool: *ObjectPool) Compiler {
        const scanner = Scanner.init();

        return Compiler{
            .scanner = scanner,
            .previous = undefined,
            .current = undefined,
            .compiling_chunk = undefined,
            .had_error = false,
            .panic_mode = false,
            .object_pool = object_pool,
        };
    }

    pub fn compile(self: *Compiler, source: []const u8, chunk: *Chunk) !bool {
        self.scanner.reset(source);
        self.compiling_chunk = chunk;

        self.had_error = false;
        self.panic_mode = false;

        self.advance();
        try self.expression();
        self.consume(.token_eof, "Expected end of expression.");

        try self.endCompiler();
        return !self.had_error;
    }

    fn advance(self: *Compiler) void {
        self.previous = self.current;
        while (true) {
            self.current = self.scanner.scanToken();
            if (self.current.token_type != .token_error) {
                break;
            }

            self.errorsAtCurrent(self.current.lexeme);
        }
    }

    fn consume(self: *Compiler, token_type: TokenType, message: []const u8) void {
        if (self.current.token_type == token_type) {
            self.advance();
            return;
        }
        self.errorsAtCurrent(message);
    }

    fn currentChunk(self: *Compiler) *Chunk {
        return self.compiling_chunk;
    }

    fn emitByte(self: *Compiler, byte: u8) !void {
        try self.currentChunk().writeChunk(byte, self.previous.line);
    }

    fn emitBytes(self: *Compiler, byte1: u8, byte2: u8) !void {
        try self.emitByte(byte1);
        try self.emitByte(byte2);
    }

    fn emitOpCode(self: *Compiler, op_code: OpCode) !void {
        try self.emitByte(@intFromEnum(op_code));
    }

    fn emitReturn(self: *Compiler) !void {
        try self.emitOpCode(.op_return);
    }

    fn makeConstant(self: *Compiler, value: Value) !u8 {
        const constant = try self.currentChunk().addConstant(value);
        if (constant > std.math.maxInt(u8)) {
            self.errors("Reached constant size limit in a chunk.");
            return 0;
        }
        return @intCast(constant);
    }

    fn emitConstant(self: *Compiler, value: Value) !void {
        try self.emitBytes(@intFromEnum(OpCode.op_constant), try self.makeConstant(value));
    }

    fn endCompiler(self: *Compiler) !void {
        try self.emitReturn();

        if (comptime config.debug_print_code) {
            if (!self.had_error) {
                debug.disassembleChunk(self.currentChunk(), "code");
            }
        }
    }

    fn binary(self: *Compiler) !void {
        const operator_type = self.previous.token_type;
        const rule = ParseRule.getRule(operator_type);
        const precedence: Precedence = @enumFromInt(@intFromEnum(rule.precedence) + 1);
        try self.parsePrecedence(precedence);

        switch (operator_type) {
            .token_bang_equal => {
                try self.emitOpCode(.op_equal);
                try self.emitOpCode(.op_not);
            },
            .token_equal_equal => try self.emitOpCode(.op_equal),
            .token_greater => try self.emitOpCode(.op_greater),
            .token_greater_equal => {
                try self.emitOpCode(.op_less);
                try self.emitOpCode(.op_not);
            },
            .token_less => try self.emitOpCode(.op_less),
            .token_less_equal => {
                try self.emitOpCode(.op_greater);
                try self.emitOpCode(.op_not);
            },
            .token_plus => try self.emitOpCode(.op_add),
            .token_minus => try self.emitOpCode(.op_substract),
            .token_star => try self.emitOpCode(.op_multiply),
            .token_slash => try self.emitOpCode(.op_divide),
            else => return,
        }
    }

    fn literal(self: *Compiler) !void {
        switch (self.previous.token_type) {
            .token_true => try self.emitOpCode(.op_true),
            .token_false => try self.emitOpCode(.op_false),
            .token_nil => try self.emitOpCode(.op_nil),
            else => unreachable,
        }
    }

    fn grouping(self: *Compiler) !void {
        try self.expression();
        self.consume(.token_rparen, "Expect ')' after expression.");
    }

    fn number(self: *Compiler) !void {
        const value = std.fmt.parseFloat(f64, self.previous.lexeme) catch 0;
        try self.emitConstant(Value.fromNumber(value));
    }

    fn string(self: *Compiler) !void {
        const lexeme = self.previous.lexeme;
        const str = try self.object_pool.createString(lexeme[1 .. lexeme.len - 1]);
        str.is_owned = false;
        try self.emitConstant(Value.fromObject(&str.object));
    }

    fn unary(self: *Compiler) !void {
        const operator_type = self.previous.token_type;

        try self.parsePrecedence(.prec_unary);

        switch (operator_type) {
            .token_minus => try self.emitOpCode(.op_negate),
            .token_bang => try self.emitOpCode(.op_not),
            else => unreachable,
        }
    }

    fn expression(self: *Compiler) !void {
        try self.parsePrecedence(.prec_assignment);
    }

    fn parsePrecedence(self: *Compiler, precedence: Precedence) !void {
        self.advance();

        if (ParseRule.getRule(self.previous.token_type).prefix) |prefixRule| {
            try prefixRule(self);

            while (@intFromEnum(ParseRule.getRule(self.current.token_type).precedence) >= @intFromEnum(precedence)) {
                self.advance();
                const infixRule = ParseRule.getRule(self.previous.token_type).infix.?;
                try infixRule(self);
            }
        } else {
            self.errors("Expect expression.");
            return;
        }
    }

    fn errors(self: *Compiler, message: []const u8) void {
        self.errorsAt(&self.previous, message);
    }

    fn errorsAtCurrent(self: *Compiler, message: []const u8) void {
        self.errorsAt(&self.current, message);
    }

    fn errorsAt(self: *Compiler, token: *Token, message: []const u8) void {
        if (self.panic_mode) return;
        self.panic_mode = true;

        const stderr = std.io.getStdErr().writer();
        stderr.print("[line {d}] Error ", .{token.line}) catch return;
        switch (token.token_type) {
            .token_eof => stderr.print("at end", .{}) catch return,
            .token_error => {
                // do nothing right now
            },
            else => stderr.print("at '{s}'", .{token.lexeme}) catch return,
        }
        stderr.print(": {s}\n", .{message}) catch return;
        self.had_error = true;
    }
};
