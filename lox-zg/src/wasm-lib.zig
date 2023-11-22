const std = @import("std");
const VM = @import("vm.zig").VM;

const allocator = std.heap.wasm_allocator;

var vm: VM = undefined;

export fn initVM() void {
    vm = VM.init(allocator) catch undefined;
}

export fn deinitVM() void {
    vm.deinit();
}

export fn interpret(ptr: [*]const u8, len: usize) void {
    const source = ptr[0..len];
    vm.interpret(source) catch return;
}

export fn alloc(len: usize) usize {
    var slice = allocator.alloc(u8, len) catch return 0;
    return @intFromPtr(slice.ptr);
}

export fn free(ptr: [*]const u8, len: usize) void {
    allocator.free(ptr[0..len]);
}
