const builtin = @import("builtin");
const std = @import("std");
usingnamespace @import("c.zig");

pub const sdl = @import("../sdl.zig");
const components = @import("../components.zig");
const Component = components.Component;
const ComponentTag = components.ComponentTag;
const Layout = components.Layout;
const Events = components.Events;

const MASK = if (builtin.endian == .Big)
    .{
        .r = 0xFF000000,
        .g = 0x00FF0000,
        .b = 0x0000FF00,
        .a = 0x000000FF,
    }
else
    .{
        .r = 0x000000FF,
        .g = 0x0000FF00,
        .b = 0x00FF0000,
        .a = 0xFF000000,
    };

fn rgba(r: u8, g: u8, b: u8, a: u8) u32 {
    if (builtin.endian == .Big) {
        return @shlExact(@as(u32, r), 24) | @shlExact(@as(u32, g), 16) | @shlExact(@as(u32, b), 8) | a;
    } else {
        return @shlExact(@as(u32, a), 24) | @shlExact(@as(u32, b), 16) | @shlExact(@as(u32, g), 8) | r;
    }
}

pub const ComponentRenderer = struct {
    alloc: *std.mem.Allocator,
    root_element: ?u32 = null,
    current_component: ?RenderedComponent = null,
    surface: *SDL_Surface,

    pub fn init(alloc: *std.mem.Allocator) !@This() {
        const screen_size = sdl.getScreenSize();
        const surface = SDL_CreateRGBSurface(0, screen_size.x, screen_size.y, 8, MASK.r, MASK.g, MASK.b, MASK.a) orelse return error.FailedToCreateSurface;
        return @This(){
            .alloc = alloc,
            .surface = surface,
        };
    }

    pub fn start() void {}

    pub fn update(self: *@This(), new_component: *const Component) !void {
        if (self.current_component) |*current_component| {
            try current_component.differences(new_component);
        } else {
            const rootElement = element_render_begin();
            self.current_component = try componentToRendered(self.alloc, new_component);
            element_appendChild(rootElement, self.current_component.?.element);
        }
    }

    pub fn render(self: *@This()) void {}

    pub fn stop(self: *@This()) void {
        sdl.sdlAssertZero(SDL_FillRect(self.surface, null, rgba(0, 0, 0, 1)));
        self.current_component = null;
    }

    pub fn deinit(self: *@This()) void {
        SDL_FreeSurface(self.SDL_Surface);
    }
};

const RenderedComponent = struct {
    alloc: *std.mem.Allocator,
    rect: SDL_Rect,
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
                    element_setText(self.element, other.Text);
                }
            },

            .Button => |*self_button| {
                if (!std.mem.eql(u8, self_button.text, other.Button.text)) {
                    element_setText(self.element, other.Button.text);
                }

                if (!std.meta.eql(self_button.events, other.Button.events)) {
                    self_button.update_events(self, other.Button.events);
                }
            },

            .Container => |*self_container| {
                if (!std.meta.eql(self_container.layout, other.Container.layout)) {
                    element_clearClasses(self.element);
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
                        element_appendChild(self.element, childElem.element);
                        self_container.children.append(childElem) catch unreachable;
                    }
                }
            },
        }
    }

    pub fn render(self: *@This(), space: SDL_Rect) void {
        switch (self.component) {
            .Text => |self_text| {},

            .Button => |*self_button| self_button.render(),

            .Container => |*self_container| self_container.render(space),
        }
    }
};

const Button = struct {
    text: []const u8,
    events: Events,

    pub fn update_events(self: *@This(), component: *const RenderedComponent, new_events: Events) void {
        if (new_events.click) |new_click| {
            element_setClickEvent(component.element, new_click);
        } else if (self.events.click) |old_click| {
            element_removeClickEvent(component.element);
        }
        self.events.click = new_events.click;

        if (new_events.hover) |new_hover| {
            element_setHoverEvent(component.element, new_hover);
        } else if (self.events.hover) |old_hover| {
            element_removeHoverEvent(component.element);
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

    pub fn render(self: *@This(), space: SDL_Rect) void {
        switch (self.layout) {
            .Flex => |orientation| {
                const space_per_component = space.w / self.children.span().len;
                for (self.children.span()) |child, idx| {
                    child.render(SDL_Rect{
                        .x = space.x + space_per_component * idx,
                        .y = space.y,
                        .w = space_per_component,
                        .h = space.h,
                    });
                }
            },
            .Grid => {},
        }
    }
};

pub const RenderingError = std.mem.Allocator.Error;

pub fn componentToRendered(alloc: *std.mem.Allocator, component: *const Component) RenderingError!RenderedComponent {
    switch (component.*) {
        .Text => |text| {
            const elem = element_create(TAG_P);
            element_setText(elem, text);
            return RenderedComponent{
                .alloc = alloc,
                .element = elem,
                .component = .{
                    .Text = try std.mem.dupe(alloc, u8, text),
                },
            };
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
            const elem = element_create(TAG_DIV);

            // Add some classes to the div
            apply_layout(elem, &container.layout);

            var rendered_children = std.ArrayList(RenderedComponent).init(alloc);
            for (container.children) |*child, idx| {
                const childElem = try componentToRendered(alloc, child);
                element_appendChild(elem, childElem.element);
                try rendered_children.append(childElem);

                if (container.layout == .Grid and container.layout.Grid.areas != null) {
                    element_setGridArea(childElem.element, idx);
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
            element_addClass(element, CLASS_FLEX);
            element_addClass(element, switch (orientation) {
                .Horizontal => CLASS_HORIZONTAL,
                .Vertical => CLASS_VERTICAL,
            });
        },
        .Grid => |template| {
            element_addClass(element, CLASS_GRID);
            if (template.areas) |areas| {
                element_setGridTemplateAreas(element, areas);
            }
            if (template.rows) |rows| {
                element_setGridTemplateRows(element, rows);
            }
            if (template.columns) |cols| {
                element_setGridTemplateColumns(element, cols);
            }
        },
    }
}
