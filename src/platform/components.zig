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

pub const Orientation = enum { Horizontal, Vertical };

pub const Layout = struct {
    orientation: Orientation = .Horizontal,

    /// How much space this component should take up on the parent component
    grow: u32 = 0,
};

pub fn text(string: []const u8) Component {
    return Component{ .Text = string };
}

pub fn button(string: []const u8, events: Events) Component {
    return Component{ .Button = .{ .text = string, .events = events } };
}

pub fn box(layout: Layout, children: []Component) Component {
    return Component{
        .Container = .{
            .layout = layout,
            .children = children,
        },
    };
}

pub fn vbox(children: var) Component {
    return box(.{ .orientation = .Vertical }, children);
}
