const std = @import("std");
const debug = @import("debug.zig");
const config = @import("config.zig");
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;
const Chunk = @import("chunk.zig").Chunk;
const Value = @import("value.zig").Value;
const OpCode = @import("chunk.zig").OpCode;
const Compiler = @import("compiler.zig").Compiler;

const InterpretError = error{
    CompileError,
    RuntimeError,
};

pub const VM = struct {
    chunk: *Chunk,
    ip: usize,
    stack: ArrayList(Value),
    stack_top: usize,
    compiler: *Compiler,
    allocator: Allocator,

    pub fn init(allocator: Allocator, compiler: *Compiler) VM {
        return VM{
            .chunk = undefined,
            .ip = 0,
            .stack = ArrayList(Value).init(allocator),
            .stack_top = 0,
            .compiler = compiler,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *VM) void {
        self.stack.deinit();
    }

    fn push(self: *VM, value: Value) !void {
        try self.stack.append(value);
        self.stack_top += 1;
    }

    fn pop(self: *VM) Value {
        self.stack_top -= 1;
        return self.stack.pop();
    }

    pub fn interpret(self: *VM, source: []const u8) !void {
        var chunk = Chunk.init(self.allocator);
        defer chunk.deinit();
        _ = try self.compiler.compile(source, &chunk);

        self.chunk = &chunk;
        self.ip = 0;

        try self.run();
    }

    fn run(self: *VM) !void {
        while (true) {
            if (comptime config.debug_trace_execution) {
                std.debug.print("          ", .{});
                for (self.stack.items) |item| {
                    std.debug.print("[ {d} ]", .{item.number});
                }
                std.debug.print("\n", .{});

                _ = debug.disassembleInstruction(self.chunk, self.ip);
            }

            const instruction: OpCode = @enumFromInt(self.readByte());
            switch (instruction) {
                .op_return => {
                    std.debug.print("{d}\n", .{self.pop().number});
                    return;
                },
                .op_constant => {
                    const constant = self.readConstant();
                    try self.push(constant);
                },
                .op_negate => {
                    const n = self.pop().number;
                    try self.push(Value{ .number = n });
                },
                .op_add => {
                    const b = self.pop().number;
                    const a = self.pop().number;
                    try self.push(Value{ .number = a + b });
                },
                .op_substract => {
                    const b = self.pop().number;
                    const a = self.pop().number;
                    try self.push(Value{ .number = a - b });
                },
                .op_multiply => {
                    const b = self.pop().number;
                    const a = self.pop().number;
                    try self.push(Value{ .number = a * b });
                },
                .op_divide => {
                    const b = self.pop().number;
                    const a = self.pop().number;
                    try self.push(Value{ .number = a / b });
                },
            }
        }
    }

    inline fn readByte(self: *VM) u8 {
        const byte = self.chunk.code.items[self.ip];
        self.ip += 1;
        return byte;
    }

    inline fn readConstant(self: *VM) Value {
        const index = self.readByte();
        return self.chunk.constants.items[index];
    }
};
