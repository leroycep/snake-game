usingnamespace @import("common.zig");
pub usingnamespace @import("webgl.zig");
pub usingnamespace @import("webgl_generated.zig");

pub extern fn consoleLogS(_: [*]const u8, _: c_uint) void;

pub extern fn now_f64() f64;

pub fn now() u64 {
    return @floatToInt(u64, now_f64());
}

pub fn getScreenSize() Vec2 {
    return .{
        .x = getScreenW(),
        .y = getScreenH(),
    };
}

pub const setShaderSource = glShaderSource;

pub fn renderPresent() void {}
