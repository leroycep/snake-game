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

pub const TAG_DIV: u32 = 1;
pub const TAG_P: u32 = 2;
pub const TAG_BUTTON: u32 = 3;

pub const CLASS_HORIZONTAL: u32 = 1;
pub const CLASS_VERTICAL: u32 = 2;
pub const CLASS_FLEX: u32 = 3;
pub const CLASS_GRID: u32 = 4;

pub extern fn element_create(tag: u32) u32;
pub extern fn element_remove(element: u32) void;
pub extern fn element_setTextS(element: u32, textPtr: [*]const u8, textLen: c_uint) void;

pub extern fn element_setClickEvent(element: u32, clickEvent: u32) void;
pub extern fn element_removeClickEvent(element: u32) void;
pub extern fn element_setHoverEvent(element: u32, hoverEvent: u32) void;
pub extern fn element_removeHoverEvent(element: u32) void;

pub extern fn element_addClass(element: u32, class: u32) void;
pub extern fn element_appendChild(element: u32, child: u32) void;
pub extern fn element_setGridArea(element: u32, grid_area: u32) void;
pub extern fn element_setGridTemplateAreasS(element: u32, grid_areas: [*]const u32, width: u32, height: u32) void;
pub extern fn element_setGridTemplateRowsS(element: u32, cols: [*]const u32, len: u32) void;
pub extern fn element_setGridTemplateColumnsS(element: u32, rows: [*]const u32, len: u32) void;

/// Returns the root element
pub extern fn element_render_begin() u32;

/// Called to clean up data on JS side
pub extern fn element_render_end() void;

pub fn element_setText(element: u32, text: []const u8) void {
    element_setTextS(element, text.ptr, text.len);
}

pub fn element_setGridTemplateRows(element: u32, cols: []const u32) void {
    element_setGridTemplateRowsS(element, cols.ptr, cols.len);
}
pub fn element_setGridTemplateColumns(element: u32, rows: []const u32) void {
    element_setGridTemplateColumnsS(element, rows.ptr, rows.len);
}


pub fn element_setGridTemplateAreas(element: u32, grid_areas: [][]const usize) void {
    const ARBITRARY_BUFFER_SIZE = 1024;
    const width = grid_areas.len;
    const height = grid_areas[0].len;
    var areas: [ARBITRARY_BUFFER_SIZE]usize = undefined;
    for (grid_areas) |row, y| {
        for (row) |area, x| {
            areas[y * width + x] = area;
        }
    }
    element_setGridTemplateAreasS(element, &areas, width, height);
}

pub fn renderComponents(rootComponent: *Component) void {
    const rootElement = element_render_begin();
    defer element_render_end();

    const element = componentToHTML(rootComponent);
    element_appendChild(rootElement, element);
}

pub fn clearComponents() void {
    const rootElement = element_render_begin();
    element_render_end();
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
            if (button.events.click) |click_event| {
                element_setClickEvent(elem, click_event);
            }
            if (button.events.hover) |hover_event| {
                element_setHoverEvent(elem, hover_event);
            }
            return elem;
        },
        .Container => |container| {
            const elem = element_create(TAG_DIV);
            element_addClass(elem, switch (container.layout.orientation) {
                .Horizontal => CLASS_HORIZONTAL,
                .Vertical => CLASS_VERTICAL,
            });
            for (container.children) |*child| {
                const childElem = componentToHTML(child);
                element_appendChild(elem, childElem);
            }
            return elem;
        },
    }
}
