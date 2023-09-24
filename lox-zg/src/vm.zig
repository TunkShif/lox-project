const std = @import("std");
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;
const OpCode = @import("chunk.zig").OpCode;
const Chunk = @import("chunk.zig").Chunk;
const Value = @import("value.zig").Value;
const compile = @import("compiler.zig").compile;

// See https://www.reddit.com/r/Zig/comments/pgo3h5/question_about_conditional_compilation_in_zig/
const is_debug_mode = (@import("builtin").mode == .Debug);

const InterpretError = error{
    CompileError,
    RuntimeError,
};

pub const VM = struct {
    chunk: *Chunk,
    ip: usize,
    stack: ArrayList(Value),
    stack_top: usize,

    pub fn init(allocator: Allocator) VM {
        // TODO: to be implemented
        return VM{
            .chunk = undefined,
            .ip = 0,
            .stack = ArrayList(Value).init(allocator),
            .stack_top = 0,
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

    pub fn interpret(self: *VM, allocator: Allocator, source: []const u8) !void {
        var chunk = Chunk.init(allocator);
        compile(source, &chunk); // TODO: Error Handling

        self.chunk = &chunk;
        self.ip = 0;

        const result = self.run();
        _ = result;

        return self.run();
    }

    fn run(self: *VM) !void {
        while (true) {
            // do conditional compilation
            if (comptime is_debug_mode) {
                const print = std.debug.print;
                const disassembleInstruction = @import("debug.zig").disassembleInstruction;

                print("          ", .{});
                for (self.stack.items) |item| {
                    print("[ {d} ]", .{item.number});
                }
                print("\n", .{});

                _ = disassembleInstruction(self.chunk, self.ip);
            }

            const instruction: OpCode = @enumFromInt(self.readByte());
            switch (instruction) {
                .op_return => {
                    std.debug.print("{d}\n", .{self.pop().number});
                },
                .op_constant => {
                    const constant = self.readConstant();
                    try self.push(constant);
                },
                .op_negate => {
                    try self.push(Value{ .number = -self.pop().number });
                },
            }
        }
    }

    inline fn readByte(self: *VM) u8 {
        self.ip += 1;
        return self.chunk.code.items[self.ip - 1];
    }

    inline fn readConstant(self: *VM) Value {
        const index = self.readByte();
        return self.chunk.constants.items[index];
    }
};
