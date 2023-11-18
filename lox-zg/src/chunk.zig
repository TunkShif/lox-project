const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const Value = @import("value.zig").Value;

pub const OpCode = enum(u8) {
    op_constant,
    op_nil,
    op_true,
    op_false,
    op_pop,
    op_get_local,
    op_get_global,
    op_define_global,
    op_set_local,
    op_set_global,
    op_equal,
    op_greater,
    op_less,
    op_add,
    op_substract,
    op_multiply,
    op_divide,
    op_negate,
    op_not,
    op_return,
};

pub const Chunk = struct {
    code: ArrayList(u8),
    lines: ArrayList(usize),
    constants: ArrayList(Value),

    pub fn init(allocator: Allocator) @This() {
        return Chunk{
            .code = ArrayList(u8).init(allocator),
            .lines = ArrayList(usize).init(allocator),
            .constants = ArrayList(Value).init(allocator),
        };
    }

    pub fn deinit(self: *@This()) void {
        self.code.deinit();
        self.lines.deinit();
        self.constants.deinit();
    }

    pub fn writeChunk(self: *@This(), byte: u8, line: usize) !void {
        try self.code.append(byte);
        try self.lines.append(line);
    }

    pub fn addConstant(self: *@This(), value: Value) !usize {
        try self.constants.append(value);
        return self.constants.items.len - 1;
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
