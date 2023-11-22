const builtin = @import("builtin");

pub const is_debug_mode = builtin.mode == .Debug;
pub const is_wasm_lib = builtin.target.isWasm() and builtin.target.os.tag == .freestanding;
pub const debug_trace_execution = is_debug_mode;
pub const debug_print_code = is_debug_mode;
