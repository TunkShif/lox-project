const std = @import("std");
const OpCode = @import("./chunk.zig").OpCode;
const Chunk = @import("./chunk.zig").Chunk;

const print = std.debug.print;

pub fn disassembleChunk(chunk: *Chunk, name: []const u8) void {
    print("== {s} ==\n", .{name});
    var offset: usize = 0;
    while (offset < chunk.code.items.len) {
        offset = disassembleInstruction(chunk, offset);
    }
}

// Disassemble the instruction with given offset and return the offset
// of the next instruction, since some instructions will take arbitrary
// amount of operands.
pub fn disassembleInstruction(chunk: *Chunk, offset: usize) usize {
    print("{d:0>4} ", .{offset});

    if (offset > 0 and chunk.lines.items[offset] == chunk.lines.items[offset - 1]) {
        print("   | ", .{});
    } else {
        print("{d: >4} ", .{chunk.lines.items[offset]});
    }

    const instruction = @intToEnum(OpCode, chunk.code.items[offset]);
    switch (instruction) {
        .op_constant => return constantInstruction("OP_CONSTANT", chunk, offset),
        .op_return => return simpleInstruction("OP_RETURN", offset),
        .op_negate => return simpleInstruction("OP_NEGATE", offset),
    }
}

fn simpleInstruction(name: []const u8, offset: usize) usize {
    print("{s}\n", .{name});
    return offset + 1;
}

fn constantInstruction(name: []const u8, chunk: *Chunk, offset: usize) usize {
    const constant = chunk.code.items[offset + 1];
    print("{s: <16} {d: >4} '{d}'\n", .{ name, constant, chunk.constants.items[constant].number });
    return offset + 2;
}
