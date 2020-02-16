const builtin = @import("builtin");

pub const is_web = builtin.arch == builtin.Arch.wasm32;
const web = @import("platform/web.zig");

pub usingnamespace if (is_web) web;

pub const Vec2 = struct { x: i32, y: i32 };
pub const Rect = struct { x: i32, y: i32, w: i32, h: i32 };

pub fn log(message: []const u8) void {
    if (is_web) {
        web.consoleLogS(message.ptr, message.len);
    }
}

pub fn getScreenSize() Vec2 {
    if (is_web) {
        return .{
            .x = web.getScreenW(),
            .y = web.getScreenH(),
        };
    }
}
