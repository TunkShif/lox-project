const std = @import("std");
const Compiler = @import("compiler.zig").Compiler;
const VM = @import("vm.zig").VM;

pub fn main() anyerror!void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();

    var vm = try VM.init(allocator);
    defer vm.deinit();

    vm.interpret("\"hello\"+\"world\"") catch return;
}
