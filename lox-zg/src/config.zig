// See https://www.reddit.com/r/Zig/comments/pgo3h5/question_about_conditional_compilation_in_zig/
pub const is_debug_mode = @import("builtin").mode == .Debug;
pub const debug_trace_execution = is_debug_mode;
pub const debug_print_code = is_debug_mode;
