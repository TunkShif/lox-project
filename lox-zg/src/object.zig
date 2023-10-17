const std = @import("std");
const Allocator = std.mem.Allocator;

pub const ObjectType = enum {
    obj_string,
};

pub const Object = struct {
    type: ObjectType,

    pub fn asString(self: *Object) *const String {
        return @fieldParentPtr(String, "object", self);
    }
};

pub const String = struct {
    object: Object,
    chars: []const u8,

    pub fn create(allocator: Allocator, source: []const u8) !*String {
        const string = try allocator.create(String);
        string.* = .{
            .object = .{
                .type = .obj_string,
            },
            .chars = source,
        };
        return string;
    }
};
