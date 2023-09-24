const std = @import("std");

pub fn main() anyerror!void {
    std.io.getStdOut().writer().print("hello!\n", .{}) catch return;
}

test "vm" {
    std.debug.print("\n", .{});

    const Chunk = @import("chunk.zig").Chunk;
    const Value = @import("value.zig").Value;
    const OpCode = @import("chunk.zig").OpCode;
    const VM = @import("vm.zig").VM;

    const allocator = std.testing.allocator;

    var chunk = Chunk.init(allocator);
    defer chunk.deinit();

    const constant = try chunk.addConstant(Value{ .number = 1.2 });
    try chunk.writeChunk(@intFromEnum(OpCode.op_constant), 123);
    try chunk.writeChunk(constant, 123);
    try chunk.writeChunk(@intFromEnum(OpCode.op_negate), 123);
    try chunk.writeChunk(@intFromEnum(OpCode.op_return), 123);

    var vm = VM.init(allocator);
    defer vm.deinit();
    try vm.interpret(&chunk);
}
