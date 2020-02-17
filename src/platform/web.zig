usingnamespace @import("common.zig");

pub extern fn consoleLogS(_: [*]const u8, _: c_uint) void;
pub extern fn getScreenW() i32;
pub extern fn getScreenH() i32;
pub extern fn clearRect(x: i32, y: i32, width: i32, height: i32) void;
pub extern fn setFillStyle(r: u8, g: u8, b: u8) void;
pub extern fn fillRect(x: i32, y: i32, width: i32, height: i32) void;

pub fn getScreenSize() Vec2 {
    return .{
        .x = getScreenW(),
        .y = getScreenH(),
    };
}

pub fn log(message: []const u8) void {
    consoleLogS(message.ptr, message.len);
}
