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
const Errors = @import("error.zig").Errors;

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

const ParseFn = *const fn (compiler: *Compiler, can_assign: bool) Errors!void;

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
    .{ .prefix = Compiler.variable, .infix = null, .precedence = .prec_none }, // token_identifier,
    .{ .prefix = Compiler.string, .infix = null, .precedence = .prec_none }, // token_string,
    .{ .prefix = Compiler.number, .infix = null, .precedence = .prec_none }, // token_number,
    .{ .prefix = null, .infix = Compiler.andExpression, .precedence = .prec_and }, // token_and,
    .{ .prefix = null, .infix = null, .precedence = .prec_none }, // token_class,
    .{ .prefix = null, .infix = null, .precedence = .prec_none }, // token_def,
    .{ .prefix = null, .infix = null, .precedence = .prec_none }, // token_else,
    .{ .prefix = Compiler.literal, .infix = null, .precedence = .prec_none }, // token_false,
    .{ .prefix = null, .infix = null, .precedence = .prec_none }, // token_for,
    .{ .prefix = null, .infix = null, .precedence = .prec_none }, // token_if,
    .{ .prefix = null, .infix = null, .precedence = .prec_none }, // token_let,
    .{ .prefix = Compiler.literal, .infix = null, .precedence = .prec_none }, // token_nil,
    .{ .prefix = null, .infix = Compiler.orExpression, .precedence = .prec_or }, // token_or,
    .{ .prefix = null, .infix = null, .precedence = .prec_none }, // token_return,
    .{ .prefix = null, .infix = null, .precedence = .prec_none }, // token_super,
    .{ .prefix = null, .infix = null, .precedence = .prec_none }, // token_this,
    .{ .prefix = Compiler.literal, .infix = null, .precedence = .prec_none }, // token_true,
    .{ .prefix = null, .infix = null, .precedence = .prec_none }, // token_while,
    .{ .prefix = null, .infix = null, .precedence = .prec_none }, // token_error,
    .{ .prefix = null, .infix = null, .precedence = .prec_none }, // token_eof,
};

const max_local_count = std.math.maxInt(u8) + 1;

const Local = struct {
    name: Token = undefined,
    depth: isize = 0,
};

pub const Compiler = struct {
    scanner: Scanner,
    previous: Token,
    current: Token,
    compiling_chunk: *Chunk,
    locals: [max_local_count]Local,
    local_count: isize,
    scope_depth: usize,
    had_error: bool,
    panic_mode: bool,
    object_pool: *ObjectPool,

    pub fn init(object_pool: *ObjectPool) @This() {
        const scanner = Scanner.init();

        return Compiler{
            .scanner = scanner,
            .previous = undefined,
            .current = undefined,
            .compiling_chunk = undefined,
            .locals = [_]Local{undefined} ** max_local_count,
            .local_count = 0,
            .scope_depth = 0,
            .had_error = false,
            .panic_mode = false,
            .object_pool = object_pool,
        };
    }

    pub fn compile(self: *@This(), source: []const u8, chunk: *Chunk) Errors!bool {
        self.scanner.reset(source);
        self.compiling_chunk = chunk;

        self.had_error = false;
        self.panic_mode = false;

        self.advance();

        while (!self.match(.token_eof)) {
            try self.declaration();
        }

        try self.endCompiler();
        return !self.had_error;
    }

    fn advance(self: *@This()) void {
        self.previous = self.current;
        while (true) {
            self.current = self.scanner.scanToken();
            if (self.current.token_type != .token_error) {
                break;
            }

            self.errorsAtCurrent(self.current.lexeme);
        }
    }

    fn consume(self: *@This(), token_type: TokenType, message: []const u8) void {
        if (self.current.token_type == token_type) {
            self.advance();
            return;
        }
        self.errorsAtCurrent(message);
    }

    fn match(self: *@This(), token_type: TokenType) bool {
        if (!self.check(token_type)) {
            return false;
        }
        self.advance();
        return true;
    }

    fn check(self: *@This(), token_type: TokenType) bool {
        return self.current.token_type == token_type;
    }

    fn currentChunk(self: *@This()) *Chunk {
        return self.compiling_chunk;
    }

    fn emitByte(self: *@This(), byte: u8) !void {
        try self.currentChunk().writeChunk(byte, self.previous.line);
    }

    fn emitBytes(self: *@This(), byte1: u8, byte2: u8) Errors!void {
        try self.emitByte(byte1);
        try self.emitByte(byte2);
    }

    fn emitJump(self: *@This(), op_code: OpCode) !usize {
        try self.emitOpCode(op_code);
        // emit a two-byte operand for op_jump_if_false instruction
        try self.emitByte(0xff);
        try self.emitByte(0xff);
        // returns the offset of the emitted instruction in the chunk
        return self.currentChunk().code.items.len - 2;
    }

    fn emitOpCode(self: *@This(), op_code: OpCode) Errors!void {
        try self.emitByte(@intFromEnum(op_code));
    }

    fn emitReturn(self: *@This()) !void {
        try self.emitOpCode(.op_return);
    }

    fn makeConstant(self: *@This(), value: Value) Errors!u8 {
        const constant = try self.currentChunk().addConstant(value);
        if (constant > std.math.maxInt(u8)) {
            self.errors("Reached constant size limit in a chunk.");
            return 0;
        }
        return @intCast(constant);
    }

    fn emitConstant(self: *@This(), value: Value) Errors!void {
        try self.emitBytes(@intFromEnum(OpCode.op_constant), try self.makeConstant(value));
    }

    fn patchJump(self: *@This(), offset: usize) void {
        // calculates byte length of the body of if branch
        const jump = self.currentChunk().code.items.len - offset - 2;
        if (jump > std.math.maxInt(u16)) {
            self.errors("Too much code to jump over.");
        }
        // store the value of `jump` as two bytes
        self.currentChunk().code.items[offset] = @intCast((jump >> 8) & 0xff);
        self.currentChunk().code.items[offset + 1] = @intCast(jump & 0xff);
    }

    fn endCompiler(self: *@This()) Errors!void {
        try self.emitReturn();

        if (comptime config.debug_print_code) {
            if (!self.had_error) {
                debug.disassembleChunk(self.currentChunk(), "code");
            }
        }
    }

    fn beginScope(self: *@This()) void {
        self.scope_depth += 1;
    }

    fn endScope(self: *@This()) Errors!void {
        self.scope_depth -= 1;

        // pop all variables in current scope when leaving a scope
        while (self.local_count > 0 and self.locals[@intCast(self.local_count - 1)].depth > self.scope_depth) {
            try self.emitOpCode(.op_pop);
            self.local_count -= 1;
        }
    }

    fn binary(self: *@This(), can_assign: bool) Errors!void {
        _ = can_assign;

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

    fn literal(self: *@This(), can_assign: bool) Errors!void {
        _ = can_assign;

        switch (self.previous.token_type) {
            .token_true => try self.emitOpCode(.op_true),
            .token_false => try self.emitOpCode(.op_false),
            .token_nil => try self.emitOpCode(.op_nil),
            else => unreachable,
        }
    }

    fn grouping(self: *@This(), can_assign: bool) Errors!void {
        _ = can_assign;

        try self.expression();
        self.consume(.token_rparen, "Expect ')' after expression.");
    }

    fn number(self: *@This(), can_assign: bool) Errors!void {
        _ = can_assign;

        const value = std.fmt.parseFloat(f64, self.previous.lexeme) catch 0;
        try self.emitConstant(Value.fromNumber(value));
    }

    fn string(self: *@This(), can_assign: bool) Errors!void {
        _ = can_assign;

        const lexeme = self.previous.lexeme;
        const str = try self.object_pool.createString(lexeme[1 .. lexeme.len - 1]);
        str.is_owned = false;
        try self.emitConstant(Value.fromObject(&str.object));
    }

    fn namedVariable(self: *@This(), name: Token, can_assign: bool) Errors!void {
        var get_op: u8 = 0;
        var set_op: u8 = 0;

        // returns -1 when it is a global variable
        var arg = self.resolveLocal(&name);

        if (arg != -1) {
            get_op = @intFromEnum(OpCode.op_get_local);
            set_op = @intFromEnum(OpCode.op_set_local);
        } else {
            arg = try self.identifierConstant(&name);
            get_op = @intFromEnum(OpCode.op_get_global);
            set_op = @intFromEnum(OpCode.op_set_global);
        }

        if (can_assign and self.match(.token_equal)) {
            try self.expression();
            try self.emitBytes(set_op, @intCast(arg));
        } else {
            try self.emitBytes(get_op, @intCast(arg));
        }
    }

    fn variable(self: *@This(), can_assign: bool) Errors!void {
        try self.namedVariable(self.previous, can_assign);
    }

    fn unary(self: *@This(), can_assign: bool) Errors!void {
        _ = can_assign;

        const operator_type = self.previous.token_type;

        try self.parsePrecedence(.prec_unary);

        switch (operator_type) {
            .token_minus => try self.emitOpCode(.op_negate),
            .token_bang => try self.emitOpCode(.op_not),
            else => unreachable,
        }
    }

    fn expression(self: *@This()) Errors!void {
        try self.parsePrecedence(.prec_assignment);
    }

    fn block(self: *@This()) Errors!void {
        while (!self.check(.token_rbrace) and !self.check(.token_eof)) {
            try self.declaration();
        }
        self.consume(.token_rbrace, "Expect '}' after block.");
    }

    fn varDeclaration(self: *@This()) Errors!void {
        const global = try self.parseVariable("Expect variable name.");

        if (self.match(.token_equal)) {
            try self.expression();
        } else {
            try self.emitOpCode(.op_nil);
        }

        self.consume(.token_semicolon, "Expect ';' after variable declaration.");
        try self.defineVariable(global);
    }

    fn declaration(self: *@This()) Errors!void {
        if (self.match(.token_let)) {
            try self.varDeclaration();
        } else {
            try self.statement();
        }

        if (self.panic_mode) {
            self.synchronize();
        }
    }

    fn statement(self: *@This()) Errors!void {
        if (self.match(.token_if)) {
            try self.ifStatement();
        } else if (self.match(.token_lbrace)) {
            self.beginScope();
            try self.block();
            try self.endScope();
        } else {
            try self.expressionStatement();
        }
    }

    fn expressionStatement(self: *@This()) Errors!void {
        try self.expression();
        self.consume(.token_semicolon, "Expect ';' after expression.");
        try self.emitOpCode(.op_pop);
    }

    fn ifStatement(self: *@This()) Errors!void {
        self.consume(.token_lparen, "Expect '(' after 'if'.");
        try self.expression();
        self.consume(.token_rparen, "Expect ')' after condition expression.");

        const then_jump = try self.emitJump(.op_jump_if_false);
        // pop the condition expression value at the first of the then branch
        // when it is truthy
        try self.emitOpCode(.op_pop);
        try self.statement();

        const else_jump = try self.emitJump(.op_jump);

        self.patchJump(then_jump);
        // pop the condition expression value before the else branch
        // when it is falsy
        try self.emitOpCode(.op_pop);

        if (self.match(.token_else)) try self.statement();
        self.patchJump(else_jump);
    }

    fn synchronize(self: *@This()) void {
        self.panic_mode = false;
        while (self.current.token_type != .token_eof) {
            if (self.previous.token_type == .token_semicolon) return;
            switch (self.current.token_type) {
                .token_class, .token_def, .token_let, .token_for, .token_if, .token_while, .token_return => return,
                else => {},
            }
            self.advance();
        }
    }

    fn parsePrecedence(self: *@This(), precedence: Precedence) Errors!void {
        self.advance();

        if (ParseRule.getRule(self.previous.token_type).prefix) |prefixRule| {
            const can_assign = @intFromEnum(precedence) <= @intFromEnum(Precedence.prec_assignment);
            try prefixRule(self, can_assign);

            while (@intFromEnum(ParseRule.getRule(self.current.token_type).precedence) >= @intFromEnum(precedence)) {
                self.advance();
                const infixRule = ParseRule.getRule(self.previous.token_type).infix.?;
                try infixRule(self, can_assign);
            }

            if (can_assign and self.match(.token_equal)) {
                self.errors("Invalid assignment target.");
            }
        } else {
            self.errors("Expect expression.");
            return;
        }
    }

    fn identifierConstant(self: *@This(), name: *const Token) Errors!u8 {
        const str = try self.object_pool.createString(name.lexeme);
        str.is_owned = false;
        return self.makeConstant(Value.fromObject(&str.object));
    }

    fn identifierEqual(self: *@This(), a: *const Token, b: *const Token) bool {
        _ = self;
        if (a.lexeme.len != b.lexeme.len) return false;
        return std.mem.eql(u8, a.lexeme, b.lexeme);
    }

    fn resolveLocal(self: *@This(), name: *const Token) isize {
        var i = self.local_count - 1;
        while (i >= 0) : (i -= 1) {
            const local = &self.locals[@intCast(i)];

            if (self.identifierEqual(name, &local.name)) {
                if (local.depth == -1) {
                    self.errors("Cannot read local variable in its own initializer");
                }
                return @intCast(i);
            }
        }

        return -1;
    }

    fn addLocal(self: *@This(), name: Token) void {
        if (self.local_count == max_local_count) {
            return self.errors("Too many local variables in function.");
        }

        const local = &self.locals[@intCast(self.local_count)];

        // use depth -1 to represent an uninitialized variable
        local.depth = -1;
        local.name = name;
        self.local_count += 1;
    }

    fn declareVariable(self: *@This()) void {
        if (self.scope_depth == 0) return;
        const name = &self.previous;

        var i = self.local_count - 1;
        while (i >= 0) : (i -= 1) {
            const local = &self.locals[@intCast(i)];

            // skip when there's no variable declared in the current scope
            if (local.depth != -1 and local.depth < self.scope_depth) break;

            // error when there's more than one variable with the same name in one scope
            if (self.identifierEqual(name, &local.name)) {
                self.errors("A variable with the same name already exists in current scope.");
            }
        }

        self.addLocal(name.*);
    }

    fn parseVariable(self: *@This(), error_message: []const u8) Errors!u8 {
        self.consume(.token_identifier, error_message);

        self.declareVariable();
        if (self.scope_depth > 0) return 0;

        return self.identifierConstant(&self.previous);
    }

    fn markInitialized(self: *@This()) void {
        // overwrite the uninitialized -1 depth with the current scope depth
        self.locals[@intCast(self.local_count - 1)].depth = @intCast(self.scope_depth);
    }

    fn defineVariable(self: *@This(), global: u8) Errors!void {
        if (self.scope_depth > 0) {
            self.markInitialized();
            return;
        }
        try self.emitBytes(@intFromEnum(OpCode.op_define_global), global);
    }

    // logical `and` and `or` operations shortcuit, so they behave just kind of like control flow
    fn andExpression(self: *@This(), can_assign: bool) Errors!void {
        _ = can_assign;
        const end_jump = try self.emitJump(.op_jump_if_false);
        try self.emitOpCode(.op_pop);
        try self.parsePrecedence(.prec_and);
        self.patchJump(end_jump);
    }

    fn orExpression(self: *@This(), can_assign: bool) Errors!void {
        _ = can_assign;
        const else_jump = try self.emitJump(.op_jump_if_false);
        const end_jump = try self.emitJump(.op_jump);

        self.patchJump(else_jump);
        try self.emitOpCode(.op_pop);

        try self.parsePrecedence(.prec_or);
        self.patchJump(end_jump);
    }

    fn errors(self: *@This(), message: []const u8) void {
        self.errorsAt(&self.previous, message);
    }

    fn errorsAtCurrent(self: *@This(), message: []const u8) void {
        self.errorsAt(&self.current, message);
    }

    fn errorsAt(self: *@This(), token: *const Token, message: []const u8) void {
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
