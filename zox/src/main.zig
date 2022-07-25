const std = @import("std");

pub fn main() anyerror!void {
    std.log.info("All your codebase are belong to us.", .{});
}

test "vm" {
    std.debug.print("\n", .{});

    const Chunk = @import("./chunk.zig").Chunk;
    const Value = @import("./value.zig").Value;
    const OpCode = @import("./chunk.zig").OpCode;
    const VM = @import("./vm.zig").VM;

    const allocator = std.testing.allocator;

    var chunk = Chunk.init(allocator);
    defer chunk.deinit();

    const constant = try chunk.addConstant(Value{ .number = 1.2 });
    try chunk.writeChunk(@enumToInt(OpCode.op_constant), 123);
    try chunk.writeChunk(constant, 123);
    try chunk.writeChunk(@enumToInt(OpCode.op_negate), 123);
    try chunk.writeChunk(@enumToInt(OpCode.op_return), 123);

    var vm = VM.init(allocator);
    defer vm.deinit();
    try vm.interpret(&chunk);
}
