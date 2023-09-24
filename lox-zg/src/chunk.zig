const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const Value = @import("value.zig").Value;

pub const OpCode = enum(u8) {
    op_constant,
    op_add,
    op_substract,
    op_multiply,
    op_divide,
    op_negate,
    op_return,
};

pub const Chunk = struct {
    code: ArrayList(u8),
    lines: ArrayList(usize),
    constants: ArrayList(Value),

    pub fn init(allocator: Allocator) Chunk {
        return Chunk{
            .code = ArrayList(u8).init(allocator),
            .lines = ArrayList(usize).init(allocator),
            .constants = ArrayList(Value).init(allocator),
        };
    }

    pub fn deinit(self: *Chunk) void {
        self.code.deinit();
        self.lines.deinit();
        self.constants.deinit();
    }

    pub fn writeChunk(self: *Chunk, byte: u8, line: usize) !void {
        try self.code.append(byte);
        try self.lines.append(line);
    }

    // Since OP_CONSTANT instruction only takes a single byte operand,
    // the maximum constant pool size is 256.
    pub fn addConstant(self: *Chunk, value: Value) !u8 {
        try self.constants.append(value);
        return @intCast(self.constants.items.len - 1);
    }
};

test "chunk" {
    std.debug.print("\n", .{});

    const debug = @import("debug.zig");
    const allocator = std.testing.allocator;

    var chunk = Chunk.init(allocator);
    defer chunk.deinit();

    const constant = try chunk.addConstant(Value{ .number = 1.2 });
    try chunk.writeChunk(@intFromEnum(OpCode.op_constant), 123);
    try chunk.writeChunk(constant, 123);
    try chunk.writeChunk(@intFromEnum(OpCode.op_return), 123);

    debug.disassembleChunk(&chunk, "test chunk");
}
