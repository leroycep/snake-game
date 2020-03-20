const std = @import("std");

pub const ComponentRenderer = @import("component_renderer.zig").ComponentRenderer;

pub const ComponentTag = enum {
    Text,
    Container,
    Button,
};

pub const Component = union(ComponentTag) {
    Text: []const u8,
    Button: Button,
    Container: Container,
};

pub const Events = struct {
    click: ?u32 = null,
    hover: ?u32 = null,

    pub fn eql(self: *const Events, other: *const Events) bool {
        if (self.click) |click| {
            if (other.click) |other_click| {
                if (click != other_click) {
                    return false;
                }
            } else {
                return false;
            }
        } else if (other.click) |other_click| {
            return false;
        }
        if (self.hover) |hover| {
            if (other.hover) |other_hover| {
                if (hover != other_hover) {
                    return false;
                }
            } else {
                return false;
            }
        } else if (other.hover) |other_hover| {
            return false;
        }
        return true;
    }
};

pub const Button = struct {
    text: []const u8,
    events: Events,
};

pub const Container = struct {
    layout: Layout,
    children: []Component,
};

pub const Mode = enum { Flex, Grid };
pub const Orientation = enum { Horizontal, Vertical };

pub const GridTemplate = struct {
    /// A 2d array of areas, with each number representing the index of the
    /// child component it is for
    areas: ?[][]usize = null,

    /// An array of the fractional units that the each component will take up.
    /// If there are more child components defined than there are fractional units
    /// given, a new row will be generated with the same fractional units.
    rows: ?[]u32 = null,
    columns: ?[]u32 = null,

    pub fn is_valid(self: *const @This(), children: []Component) bool {
        var at_least_one_not_null = false;
        var num_rows: ?usize = null;
        var num_cols: ?usize = null;
        if (self.areas) |areas| {
            at_least_one_not_null = true;
            num_rows = areas.len;
            num_cols = areas[0].len;
            for (areas) |row| {
                if (row.len != num_cols.?) {
                    return false; // Rows must be a uniform length
                }
                for (row) |area| {
                    if (area >= children.len) {
                        return false; // There is an area used that does not exist
                    }
                }
            }
        }
        if (self.rows) |rows| {
            at_least_one_not_null = true;
            if (num_rows) |nrows| {
                if (rows.len != nrows) return false; // Number of rows in grid area and rows don't match
            }
        }
        if (self.columns) |cols| {
            at_least_one_not_null = true;
            if (num_cols) |ncols| {
                if (cols.len != ncols) return false; // Number of columns in grid area and rows don't match
            }
        }
        return at_least_one_not_null;
    }
};

pub const Layout = union(Mode) {
    Flex: Orientation,
    Grid: GridTemplate,

    pub fn grid(template: GridTemplate) @This() {
        return .{ .Grid = template };
    }

    pub fn flex(orientation: Orientation) @This() {
        return .{ .Flex = orientation };
    }

    pub fn is_valid(self: *const @This(), children: []Component) bool {
        return switch (self.*) {
            .Flex => true,
            .Grid => |template| template.is_valid(children),
        };
    }
};

pub fn text(string: []const u8) Component {
    return Component{ .Text = string };
}

pub fn button(string: []const u8, events: Events) Component {
    return Component{ .Button = .{ .text = string, .events = events } };
}

pub fn box(layout: Layout, children: []Component) Component {
    std.debug.assert(layout.is_valid(children));
    return Component{
        .Container = .{
            .layout = layout,
            .children = children,
        },
    };
}
