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

pub const Button = struct {
    text: []const u8,
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

pub fn button(string: []const u8) Component {
    return Component{ .Button = .{ .text = string } };
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
