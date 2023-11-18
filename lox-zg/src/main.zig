const std = @import("std");
const VM = @import("vm.zig").VM;

pub fn main() anyerror!void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();

    var vm = try VM.init(allocator);
    defer vm.deinit();

    const source =
        \\let outer = "first";
        \\{
        \\  let captured = outer;
        \\  let inner = captured + " and second";
        \\  let outer = "redefined";
        \\  {
        \\  let nested = "another layer";
        \\  }
        \\}
        \\captured;
    ;

    vm.interpret(source) catch return;
}
