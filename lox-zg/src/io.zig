const std = @import("std");
const config = @import("config.zig");
const console = @import("js/console.zig");

pub const Writer = if (config.is_wasm_lib) console.Console.Writer else std.fs.File.Writer;
