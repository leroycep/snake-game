const std = @import("std");
const builtin = @import("builtin");
const platform = @import("platform.zig");
usingnamespace @import("constants.zig");
const Vec2f = platform.Vec2f;
const pi = std.math.pi;
const Renderer = @import("renderer.zig").Renderer;
const ring_buffer = @import("ring_buffer.zig");
const RingBuffer = ring_buffer.RingBuffer;
const collision = @import("collision.zig");
const OBB = collision.OBB;
const screen = @import("screen.zig");
const game = @import("game.zig");

var renderer: Renderer = undefined;

var alloc = std.heap.direct_allocator;
var screen_stack: std.ArrayList(*screen.Screen) = undefined;

pub fn onInit() void {
    renderer = Renderer.init();

    screen_stack = std.ArrayList(*screen.Screen).init(alloc);
    const main_menu = screen.MainMenu.init(alloc) catch unreachable;
    screen_stack.append(&main_menu.screen) catch unreachable;
}

pub fn onEvent(event: platform.Event) void {
    const current_screen = screen_stack.toSlice()[screen_stack.len - 1];

    current_screen.onEvent(event);
}

pub fn update(current_time: f64, delta: f64) void {
    const current_screen = screen_stack.toSlice()[screen_stack.len - 1];

    const transition_opt = current_screen.update(current_time, delta);

    if (transition_opt) |transition| {
        switch (transition) {
            .Push => |new_screen| {
                screen_stack.append(new_screen) catch unreachable;
            },
            .Replace => |new_screen| {
                screen_stack.toSlice()[screen_stack.len - 1] = new_screen;
            },
            .Pop => {
                _ = screen_stack.pop();
            },
        }
    }
}

pub fn render(alpha: f64) void {
    const current_screen = screen_stack.toSlice()[screen_stack.len - 1];

    renderer.begin();

    current_screen.render(&renderer, alpha);

    renderer.flush();
    platform.renderPresent();
}

test "" {
    std.meta.refAllDecls(ring_buffer);
}
