const std = @import("std");
const debug = @import("debug.zig");
const config = @import("config.zig");
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;
const Chunk = @import("chunk.zig").Chunk;
const Value = @import("value.zig").Value;
const Object = @import("object.zig").Object;
const String = @import("object.zig").String;
const OpCode = @import("chunk.zig").OpCode;
const Compiler = @import("compiler.zig").Compiler;
const ObjectPool = @import("object.zig").ObjectPool;

const InterpretError = error{
    CompileError,
    RuntimeError,
};

pub const VM = struct {
    chunk: *Chunk,
    ip: usize,
    stack: ArrayList(Value),
    stack_top: usize,
    compiler: Compiler,
    object_pool: *ObjectPool,
    allocator: Allocator,

    pub fn init(allocator: Allocator) !@This() {
        const object_pool = try allocator.create(ObjectPool);
        object_pool.* = ObjectPool.init(allocator);
        var compiler = Compiler.init(object_pool);

        return VM{
            .chunk = undefined,
            .ip = 0,
            .stack = ArrayList(Value).init(allocator),
            .stack_top = 0,
            .compiler = compiler,
            .allocator = allocator,
            .object_pool = object_pool,
        };
    }

    pub fn deinit(self: *@This()) void {
        self.stack.deinit();
        self.object_pool.deinit();
        self.allocator.destroy(self.object_pool);
    }

    pub fn interpret(self: *@This(), source: []const u8) !void {
        var chunk = Chunk.init(self.allocator);
        defer chunk.deinit();
        _ = try self.compiler.compile(source, &chunk);

        self.chunk = &chunk;
        self.ip = 0;

        try self.run();
    }

    fn run(self: *@This()) !void {
        while (true) {
            if (comptime config.debug_trace_execution) {
                std.debug.print("          ", .{});
                for (self.stack.items) |item| {
                    std.debug.print("[{}]", .{item});
                }
                std.debug.print("\n", .{});

                _ = debug.disassembleInstruction(self.chunk, self.ip);
            }

            const instruction: OpCode = @enumFromInt(self.readByte());
            switch (instruction) {
                .op_return => {
                    std.debug.print("{}\n", .{self.pop()});
                    return;
                },
                .op_constant => {
                    const constant = self.readConstant();
                    try self.push(constant);
                },
                .op_true => {
                    try self.push(Value.fromBool(true));
                },
                .op_false => {
                    try self.push(Value.fromBool(false));
                },
                .op_nil => {
                    try self.push(Value.fromNil());
                },
                .op_equal => {
                    const b = self.pop();
                    const a = self.pop();
                    try self.push(Value.fromBool(a.equals(b)));
                },
                .op_negate => {
                    if (!self.peek(0).isNumber()) {
                        try self.runtimeErrors("Operand must be a number", .{});
                        return InterpretError.RuntimeError;
                    }

                    const n = self.pop().number;
                    try self.push(Value.fromNumber(-n));
                },
                .op_not => {
                    try self.push(Value.fromBool(self.pop().isFalsy()));
                },
                .op_add => {
                    try self.addOperation();
                },
                .op_substract, .op_multiply, .op_divide, .op_greater, .op_less => {
                    try self.binaryOperation(instruction);
                },
            }
        }
    }

    inline fn readByte(self: *@This()) u8 {
        const byte = self.chunk.code.items[self.ip];
        self.ip += 1;
        return byte;
    }

    inline fn readConstant(self: *@This()) Value {
        const index = self.readByte();
        return self.chunk.constants.items[index];
    }

    fn binaryOperation(self: *@This(), op_code: OpCode) !void {
        if (!self.peek(0).isNumber() or !self.peek(1).isNumber()) {
            try self.runtimeErrors("Operands must be numbers", .{});
            return InterpretError.RuntimeError;
        }

        const b = self.pop().number;
        const a = self.pop().number;
        const value = switch (op_code) {
            .op_substract => Value.fromNumber(a - b),
            .op_multiply => Value.fromNumber(a * b),
            .op_divide => Value.fromNumber(a / b),
            .op_greater => Value.fromBool(a > b),
            .op_less => Value.fromBool(a < b),
            else => unreachable,
        };
        try self.push(value);
    }

    fn addOperation(self: *@This()) !void {
        if (self.peek(0).isString() and self.peek(1).isString()) {
            const b = self.pop().object.asString();
            const a = self.pop().object.asString();
            const buffer = try self.allocator.alloc(u8, a.chars.len + b.chars.len);
            const joined = try std.fmt.bufPrint(buffer, "{s}{s}", .{ a.chars, b.chars });
            const string = try self.object_pool.createString(joined);
            try self.push(Value.fromObject(&string.object));
        } else if (self.peek(0).isNumber() and self.peek(1).isNumber()) {
            const b = self.pop().number;
            const a = self.pop().number;
            try self.push(Value.fromNumber(a + b));
        } else {
            try self.runtimeErrors("Operands must be both numbers or strings.", .{});
            return InterpretError.RuntimeError;
        }
    }

    fn push(self: *@This(), value: Value) !void {
        try self.stack.append(value);
        self.stack_top += 1;
    }

    fn pop(self: *@This()) Value {
        self.stack_top -= 1;
        return self.stack.pop();
    }

    fn peek(self: *@This(), distance: usize) Value {
        return self.stack.items[self.stack.items.len - distance - 1];
    }

    fn resetStack(self: *@This()) void {
        self.stack.clearRetainingCapacity();
        self.stack_top = 0;
    }

    fn runtimeErrors(self: *@This(), comptime format: []const u8, args: anytype) !void {
        const stderr = std.io.getStdErr().writer();
        try stderr.print(format, args);
        _ = try stderr.write("\n");

        const line = self.chunk.lines.items[self.ip - 1];
        try stderr.print("[line {d}] in script\n", .{line});
        self.resetStack();
    }
};
