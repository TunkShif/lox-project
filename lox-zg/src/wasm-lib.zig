const std = @import("std");
const VM = @import("vm.zig").VM;

const allocator = std.heap.wasm_allocator;

var vm: VM = undefined;

pub export fn initVM() !void {
    vm = try VM.init(allocator);
}

pub export fn deinitVM() !void {
    vm.deinit();
}

pub export fn interpret(ptr: [*]const u8, len: usize) void {
    const source = ptr[0..len];
    vm.interpret(source) catch return;
}

pub export fn alloc(len: usize) usize {
    var slice = allocator.alloc(u8, len) catch return 0;
    return @intFromPtr(slice.ptr);
}

pub export fn free(ptr: [*]const u8, len: usize) void {
    allocator.free(ptr[0..len]);
}
