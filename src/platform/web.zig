usingnamespace @import("common.zig");
pub usingnamespace @import("web/webgl.zig");
pub usingnamespace @import("web/webgl_generated.zig");
const Component = @import("components.zig").Component;
const warn = @import("../platform.zig").warn;
pub const ComponentRenderer = @import("web/component_renderer.zig").ComponentRenderer;

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
