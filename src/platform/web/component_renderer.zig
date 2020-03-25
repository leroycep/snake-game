const std = @import("std");
const components = @import("../components.zig");
const Component = components.Component;
const ComponentTag = components.ComponentTag;
const Layout = components.Layout;
const Events = components.Events;

const web = @import("../web.zig");

pub const ComponentRenderer = struct {
    alloc: *std.mem.Allocator,
    root_element: ?u32 = null,
    current_component: ?RenderedComponent = null,

    pub fn init(alloc: *std.mem.Allocator) !@This() {
        return @This(){
            .alloc = alloc,
        };
    }

    pub fn start() void {}

    pub fn render(self: *@This(), new_component: *const Component) !void {
        if (self.current_component) |*current_component| {
            try current_component.differences(new_component);
        } else {
            const rootElement = web.element_render_begin();
            self.current_component = try componentToRendered(self.alloc, new_component);
            web.element_appendChild(rootElement, self.current_component.?.element);
        }
    }

    pub fn stop(self: *@This()) void {
        self.current_components = null;
    }
};

const RenderedComponent = struct {
    alloc: *std.mem.Allocator,
    element: u32,
    component: union(ComponentTag) {
        Text: []const u8,
        Button: Button,
        Container: Container,

        pub fn deinit(self: *@This(), component: *RenderedComponent) void {
            switch (self.*) {
                .Text => |text| component.alloc.free(text),
                .Button => |button| component.alloc.free(button.text),
                .Container => |*container| container.deinit(component),
            }
        }
    },

    pub fn remove(self: *@This()) void {
        web.element_remove(self.element);
        self.component.deinit(self);
    }

    pub fn deinit(self: *@This()) void {
        self.component.deinit(self);
    }

    pub fn differences(self: *@This(), other: *const Component) RenderingError!void {
        if (@as(ComponentTag, self.component) != @as(ComponentTag, other.*)) {
            self.remove();
            self.* = try componentToRendered(self.alloc, other);
            return;
        }
        // Tags must be equal
        switch (self.component) {
            .Text => |self_text| {
                if (!std.mem.eql(u8, self_text, other.Text)) {
                    web.element_setText(self.element, other.Text);
                }
            },

            .Button => |*self_button| {
                if (!std.mem.eql(u8, self_button.text, other.Button.text)) {
                    web.element_setText(self.element, other.Button.text);
                }

                if (!std.meta.eql(self_button.events, other.Button.events)) {
                    self_button.update_events(self, other.Button.events);
                }
            },

            .Container => |*self_container| {
                if (!std.meta.eql(self_container.layout, other.Container.layout)) {
                    web.element_clearClasses(self.element);
                    apply_layout(self.element, &other.Container.layout);
                }
                var changed = other.Container.children.len != self_container.children.len;
                var idx: usize = 0;
                while (!changed and idx < other.Container.children.len) : (idx += 1) {
                    const self_child = &self_container.children.span()[idx];
                    const other_child = &other.Container.children[idx];
                    if (@as(ComponentTag, self_child.component) == @as(ComponentTag, other_child.*)) {
                        try self_child.differences(other_child);
                    } else {
                        changed = true;
                    }
                }

                if (changed) {
                    // Clear children and rebuild
                    self_container.removeChildren();
                    for (other.Container.children) |*other_child| {
                        const childElem = try componentToRendered(self.alloc, other_child);
                        web.element_appendChild(self.element, childElem.element);
                        self_container.children.append(childElem) catch unreachable;
                    }
                }
            },
        }
    }
};

const Button = struct {
    text: []const u8,
    events: Events,

    pub fn update_events(self: *@This(), component: *const RenderedComponent, new_events: Events) void {
        if (new_events.click) |new_click| {
            web.element_setClickEvent(component.element, new_click);
        } else if (self.events.click) |old_click| {
            web.element_removeClickEvent(component.element);
        }
        self.events.click = new_events.click;

        if (new_events.hover) |new_hover| {
            web.element_setHoverEvent(component.element, new_hover);
        } else if (self.events.hover) |old_hover| {
            web.element_removeHoverEvent(component.element);
        }
        self.events.hover = new_events.hover;
    }
};

pub const Container = struct {
    layout: Layout,
    children: std.ArrayList(RenderedComponent),

    pub fn removeChildren(self: *@This()) void {
        for (self.children.span()) |*child| {
            child.remove();
        }
        self.children.resize(0) catch unreachable;
    }

    pub fn deinit(self: *@This(), component: *RenderedComponent) void {
        for (self.children.span()) |*child| {
            child.deinit();
        }
        self.children.deinit();
    }
};

pub const RenderingError = std.mem.Allocator.Error;

pub fn componentToRendered(alloc: *std.mem.Allocator, component: *const Component) RenderingError!RenderedComponent {
    switch (component.*) {
        .Text => |text| {
            const elem = web.element_create(web.TAG_P);
            web.element_setText(elem, text);
            return RenderedComponent{
                .alloc = alloc,
                .element = elem,
                .component = .{
                    .Text = try std.mem.dupe(alloc, u8, text),
                },
            };
        },
        .Button => |button| {
            const elem = web.element_create(web.TAG_BUTTON);
            web.element_setText(elem, button.text);
            if (button.events.click) |click_event| {
                web.element_setClickEvent(elem, click_event);
            }
            if (button.events.hover) |hover_event| {
                web.element_setHoverEvent(elem, hover_event);
            }
            return RenderedComponent{
                .alloc = alloc,
                .element = elem,
                .component = .{
                    .Button = .{
                        .text = try std.mem.dupe(alloc, u8, button.text),
                        .events = button.events,
                    },
                },
            };
        },
        .Container => |container| {
            const elem = web.element_create(web.TAG_DIV);

            // Add some classes to the div
            apply_layout(elem, &container.layout);

            var rendered_children = std.ArrayList(RenderedComponent).init(alloc);
            for (container.children) |*child, idx| {
                const childElem = try componentToRendered(alloc, child);
                web.element_appendChild(elem, childElem.element);
                try rendered_children.append(childElem);

                if (container.layout == .Grid and container.layout.Grid.areas != null) {
                    web.element_setGridArea(childElem.element, idx);
                }
            }

            return RenderedComponent{
                .alloc = alloc,
                .element = elem,
                .component = .{
                    .Container = .{
                        .layout = container.layout,
                        .children = rendered_children,
                    },
                },
            };
        },
    }
}

pub fn apply_layout(element: u32, layout: *const Layout) void {
    switch (layout.*) {
        .Flex => |orientation| {
            web.element_addClass(element, web.CLASS_FLEX);
            web.element_addClass(element, switch (orientation) {
                .Horizontal => web.CLASS_HORIZONTAL,
                .Vertical => web.CLASS_VERTICAL,
            });
        },
        .Grid => |template| {
            web.element_addClass(element, web.CLASS_GRID);
            if (template.areas) |areas| {
                web.element_setGridTemplateAreas(element, areas);
            }
            if (template.rows) |rows| {
                web.element_setGridTemplateRows(element, rows);
            }
            if (template.columns) |cols| {
                web.element_setGridTemplateColumns(element, cols);
            }
        },
    }
}
