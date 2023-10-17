const std = @import("std");
const Object = @import("object.zig").Object;

pub const Value = union(enum) {
    nil,
    bool: bool,
    number: f64,
    object: *Object,

    pub fn fromObject(value: *Object) Value {
        return Value{ .object = value };
    }

    pub fn fromNumber(value: f64) Value {
        return Value{ .number = value };
    }

    pub fn fromBool(value: bool) Value {
        return Value{ .bool = value };
    }

    pub fn fromNil() Value {
        return .nil;
    }

    pub fn isNumber(self: Value) bool {
        return self == .number;
    }

    pub fn isObject(self: Value) bool {
        return self == .object;
    }

    pub fn isString(self: Value) bool {
        return self == .object and self.object.type == .obj_string;
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
            .object => |value| {
                const a = value.asString();
                const b = value.asString();
                return a.chars.len == b.chars.len and std.mem.eql(u8, a.chars, b.chars);
            },
        };
    }

    pub fn format(self: Value, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = fmt;
        _ = options;
        switch (self) {
            .nil => try writer.print("nil", .{}),
            .bool => |value| try writer.print("{}", .{value}),
            .number => |value| try writer.print("{d}", .{value}),
            .object => |value| {
                switch (value.type) {
                    .obj_string => try writer.print("{s}", .{value.asString().chars}),
                }
            },
        }
    }
};
