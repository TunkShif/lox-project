const std = @import("std");
const Compiler = @import("compiler.zig").Compiler;
const VM = @import("vm.zig").VM;

pub fn main() anyerror!void {
    std.io.getStdOut().writer().print("hello!\n", .{}) catch return;

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();

    var compiler = Compiler.init();
    var vm = VM.init(allocator, &compiler);
    defer vm.deinit();

    vm.interpret("!(5 - 4 > 3 * 2 == !nil)") catch return;
}
