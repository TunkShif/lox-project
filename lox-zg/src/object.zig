const std = @import("std");
const Allocator = std.mem.Allocator;
const Errors = @import("error.zig").Errors;

pub const ObjectType = enum {
    obj_string,

    pub fn enumFromType(comptime T: type) @This() {
        return switch (T) {
            String => .obj_string,
            else => @compileError("Unknown object type."),
        };
    }
};

pub const Object = struct {
    type: ObjectType,
    next: ?*Object = null,

    pub fn asString(self: *@This()) *const String {
        return @fieldParentPtr(String, "object", self);
    }
};

pub const String = struct {
    object: Object,
    chars: []const u8,
    is_owned: bool = true,
};

// object creation is needed at both compile-time and runtime,
// so I created an object pool shared by compiler and vm to avoid coupling
pub const ObjectPool = struct {
    objects: ?*Object,
    allocator: Allocator,

    pub fn init(allocator: Allocator) @This() {
        return ObjectPool{
            .objects = null,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *@This()) void {
        self.freeObjects();
        self.objects = null;
    }

    pub fn createObject(self: *@This(), comptime T: type) Errors!*T {
        const instance = self.allocator.create(T) catch return Errors.AllocationError;
        instance.object.type = ObjectType.enumFromType(T);
        instance.object.next = self.objects;
        self.objects = &instance.object;
        return instance;
    }

    pub fn createString(self: *@This(), source: []const u8) Errors!*String {
        const string = try self.createObject(String);
        string.chars = source;
        string.is_owned = true;
        return string;
    }

    fn destroyObject(self: *@This(), object: *Object) void {
        switch (object.type) {
            .obj_string => {
                const string = object.asString();
                if (string.is_owned) {
                    self.allocator.free(string.chars);
                }
                self.allocator.destroy(string);
            },
        }
    }

    fn freeObjects(self: *@This()) void {
        var object = self.objects;
        while (object) |o| {
            const next = o.next;
            self.destroyObject(o);
            object = next;
        }
    }
};
