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
    const main_menu = screen.Game.init(alloc) catch unreachable;
    screen_stack.append(&main_menu.screen) catch unreachable;
}

pub fn onEvent(event: platform.Event) void {
    const current_screen = screen_stack.toSlice()[screen_stack.len - 1];

    current_screen.onEvent(event);
}

pub fn update(current_time: f64, delta: f64) void {
    const current_screen = screen_stack.toSlice()[screen_stack.len - 1];

    current_screen.update(current_time, delta);
}

fn mulMat4(a: []const f32, b: []const f32) [16]f32 {
    std.debug.assert(a.len == 16);
    std.debug.assert(b.len == 16);

    var c: [16]f32 = undefined;
    comptime var i: usize = 0;
    inline while (i < 4) : (i += 1) {
        comptime var j: usize = 0;
        inline while (j < 4) : (j += 1) {
            c[i * 4 + j] = 0;
            comptime var k: usize = 0;
            inline while (k < 4) : (k += 1) {
                c[i * 4 + j] += a[i * 4 + k] * b[k * 4 + j];
            }
        }
    }
    return c;
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
