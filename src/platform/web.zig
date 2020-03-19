usingnamespace @import("common.zig");
pub usingnamespace @import("webgl.zig");
pub usingnamespace @import("webgl_generated.zig");
const Component = @import("components.zig").Component;

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

const TAG_DIV: u32 = 1;
const TAG_P: u32 = 2;
const TAG_BUTTON: u32 = 3;

extern fn element_create(tag: u32) u32;
extern fn element_setTextS(element: u32, textPtr: [*]const u8, textLen: c_uint) void;
extern fn element_appendChild(element: u32, child: u32) void;

/// Returns the root element
extern fn element_render_begin() u32;

/// Called to clean up data on JS side
extern fn element_render_end() void;

fn element_setText(element: u32, text: []const u8) void {
    element_setTextS(element, text.ptr, text.len);
}

pub fn renderComponents(rootComponent: *Component) void {
    const rootElement = element_render_begin();
    defer element_render_end();

    const element = componentToHTML(rootComponent);
    element_appendChild(rootElement, element);
}

pub fn componentToHTML(component: *Component) u32 {
    switch (component.*) {
        .Text => |text| {
            const elem = element_create(TAG_P);
            element_setText(elem, text);
            return elem;
        },
        .Button => |button| {
            const elem = element_create(TAG_BUTTON);
            element_setText(elem, button.text);
            return elem;
        },
        .Container => |container| {
            const elem = element_create(TAG_DIV);
            for (container.children) |*child| {
                const childElem = componentToHTML(child);
                element_appendChild(elem, childElem);
            }
            return elem;
        },
    }
}
