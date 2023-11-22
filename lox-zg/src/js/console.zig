const std = @import("std");

extern fn consoleWrite(ptr: [*]const u8, len: usize) void;
extern fn consoleFlush() void;

pub const Console = struct {
    const Self = @This();
    pub const Error = error{IOError};
    pub const Writer = std.io.Writer(*Self, Error, write);

    pub fn write(self: *Self, bytes: []const u8) Error!usize {
        _ = self;
        consoleWrite(bytes.ptr, bytes.len);
        return bytes.len;
    }
};

pub fn getWriter() Console.Writer {
    return Console.Writer{ .context = undefined };
}
