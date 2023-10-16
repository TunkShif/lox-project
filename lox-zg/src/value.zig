const std = @import("std");

pub const Value = union(enum) {
    nil,
    bool: bool,
    number: f64,

    pub fn fromNumber(value: f64) Value {
        return Value{ .number = value };
    }

    pub fn fromBool(value: bool) Value {
        return Value{ .bool = value };
    }

    pub fn fromNil() Value {
        return .nil;
    }

    pub fn asNumber(self: Value) f64 {
        return self.number;
    }

    pub fn isNumber(self: Value) bool {
        return self == .number;
    }

    pub fn isFalsy(self: Value) bool {
        return switch (self) {
            .nil => true,
            .bool => |value| !value,
            else => false,
        };
    }

    pub fn equals(self: Value, other: Value) bool {
        if (!std.mem.eql(u8, @tagName(self), @tagName(other))) return false;
        return switch (self) {
            .nil => true,
            .bool => self.bool == other.bool,
            .number => self.number == other.number,
        };
    }

    pub fn format(self: Value, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = fmt;
        _ = options;
        switch (self) {
            .nil => try writer.print("nil", .{}),
            .bool => |value| try writer.print("{}", .{value}),
            .number => |value| try writer.print("{d}", .{value}),
        }
    }
};
