const builtin = @import("builtin");
const std = @import("std");
usingnamespace @import("c.zig");

pub const Renderer = @import("../renderer.zig").Renderer;
const common = @import("../common.zig");
const Rect = common.Rect;
const Vec2f = common.Vec2f;
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
    current_component: ?RenderedComponent = null,

    pub fn init(alloc: *std.mem.Allocator) !@This() {
        return @This(){
            .alloc = alloc,
        };
    }

    pub fn update(self: *@This(), new_component: *const Component) !void {
        self.current_component = try componentToRendered(self.alloc, new_component);
    }

    pub fn render(self: *@This(), renderer: *Renderer) void {
        if (self.current_component) |*component| {
            const screen_size = sdl.getScreenSize();
            const space = Rect{
                .x = 0,
                .y = 0,
                .w = screen_size.x,
                .h = screen_size.y,
            };
            component.render(renderer, space);
        }
    }

    pub fn clear(self: *@This()) void {
        self.current_component = null;
    }

    pub fn deinit(self: *@This()) void {
        SDL_FreeSurface(self.SDL_Surface);
    }
};

const RenderedComponent = struct {
    alloc: *std.mem.Allocator,
    component: union(ComponentTag) {
        Text: Text,
        Button: Button,
        Container: Container,

        pub fn deinit(self: *@This(), component: *RenderedComponent) void {
            switch (self.*) {
                .Text => |text| component.alloc.free(text.text),
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

    pub fn render(self: *@This(), renderer: *Renderer, space: Rect) void {
        switch (self.component) {
            .Text => |*self_text| self_text.render(renderer, space),
            .Button => |*self_button| self_button.render(renderer, space),
            .Container => |*self_container| self_container.render(renderer, space),
        }
    }
};

const Text = struct {
    text: []const u8,

    pub fn render(self: *@This(), renderer: *Renderer, space: Rect) void {
        const size = Vec2f{
            .x = @intToFloat(f32, space.w),
            .y = @intToFloat(f32, space.h),
        };
        const center = (Vec2f{
            .x = @intToFloat(f32, space.x),
            .y = @intToFloat(f32, space.y),
        }).add(&size.scalMul(0.5));
        renderer.pushRect(center, size.scalMul(0.8), .{ .r = 200, .g = 230, .b = 200 }, 0);
    }
};

const Button = struct {
    text: []const u8,
    events: Events,

    pub fn render(self: *@This(), renderer: *Renderer, space: Rect) void {
        const size = Vec2f{
            .x = @intToFloat(f32, space.w) / 2,
            .y = @intToFloat(f32, space.h) / 2,
        };
        const center = (Vec2f{
            .x = @intToFloat(f32, space.x),
            .y = @intToFloat(f32, space.y),
        }).add(&size);
        renderer.pushRect(center, size, .{ .r = 255, .g = 255, .b = 255 }, 0);
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

    pub fn render(self: *@This(), renderer: *Renderer, space: Rect) void {
        switch (self.layout) {
            .Flex => |orientation| {
                const axisSize = switch (orientation) {
                    .Horizontal => space.w,
                    .Vertical => space.h,
                };
                const space_per_component = @divTrunc(axisSize, @intCast(i32, self.children.span().len));
                for (self.children.span()) |*child, idx| {
                    const childSpace = switch (orientation) {
                        .Horizontal => Rect{
                            .x = space.x + space_per_component * @intCast(i32, idx),
                            .y = space.y,
                            .w = space_per_component,
                            .h = space.h,
                        },
                        .Vertical => Rect{
                            .x = space.x,
                            .y = space.y + space_per_component * @intCast(i32, idx),
                            .w = space.w,
                            .h = space_per_component,
                        },
                    };
                    child.render(renderer, childSpace);
                }
            },
            .Grid => |template| {
                // TODO: actually do grid layout
                const space_per_component = @divTrunc(space.w, @intCast(i32, self.children.span().len));
                for (self.children.span()) |*child, idx| {
                    child.render(renderer, Rect{
                        .x = space.x + space_per_component * @intCast(i32, idx),
                        .y = space.y,
                        .w = space_per_component,
                        .h = space.h,
                    });
                }
            },
        }
    }
};

pub const RenderingError = std.mem.Allocator.Error;

pub fn componentToRendered(alloc: *std.mem.Allocator, component: *const Component) RenderingError!RenderedComponent {
    switch (component.*) {
        .Text => |text| {
            return RenderedComponent{
                .alloc = alloc,
                .component = .{
                    .Text = .{ .text = try std.mem.dupe(alloc, u8, text) },
                },
            };
        },
        .Button => |button| {
            return RenderedComponent{
                .alloc = alloc,
                .component = .{
                    .Button = .{
                        .text = try std.mem.dupe(alloc, u8, button.text),
                        .events = button.events,
                    },
                },
            };
        },
        .Container => |container| {
            var rendered_children = std.ArrayList(RenderedComponent).init(alloc);
            for (container.children) |*child, idx| {
                const childElem = try componentToRendered(alloc, child);
                try rendered_children.append(childElem);
            }

            return RenderedComponent{
                .alloc = alloc,
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
