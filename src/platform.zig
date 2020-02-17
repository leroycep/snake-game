const builtin = @import("builtin");
pub usingnamespace @import("platform/common.zig");

pub const is_web = builtin.arch == builtin.Arch.wasm32;
const web = @import("platform/web.zig");
const sdl = @import("platform/sdl.zig");

pub usingnamespace if (is_web) web else sdl;

pub var quit = false;
