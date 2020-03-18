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
var snake: game.Snake = undefined;

var random: std.rand.DefaultPrng = undefined;
var food_pos: ?Vec2f = null;

var inputs = Inputs{};

var alloc = std.heap.direct_allocator;
var screen_stack: std.ArrayList(*screen.Screen) = undefined;

/// Keep track of D-Pad status
const Inputs = struct {
    north: bool = false,
    east: bool = false,
    south: bool = false,
    west: bool = false,
};

pub fn onInit() void {
    renderer = Renderer.init();

    screen_stack = std.ArrayList(*screen.Screen).init(alloc);
    const main_menu = screen.MainMenu.init(alloc) catch unreachable;
    screen_stack.append(&main_menu.screen) catch unreachable;

    snake = game.Snake.init(alloc) catch unreachable;
    snake.addSegment();

    random = std.rand.DefaultPrng.init(1337);
}

pub fn onEvent(event: platform.Event) void {
    switch (event) {
        .Quit => platform.quit(),
        .ScreenResized => |screen_size| platform.glViewport(0, 0, screen_size.x, screen_size.y),
        .KeyDown => |ev| switch (ev.scancode) {
            .ESCAPE => platform.quit(),
            .UP => inputs.north = true,
            .RIGHT => inputs.east = true,
            .DOWN => inputs.south = true,
            .LEFT => inputs.west = true,
            else => {},
        },
        .KeyUp => |ev| switch (ev.scancode) {
            .UP => inputs.north = false,
            .RIGHT => inputs.east = false,
            .DOWN => inputs.south = false,
            .LEFT => inputs.west = false,
            else => {},
        },
        else => {},
    }
}

pub fn update(current_time: f64, delta: f64) void {
    const current_screen = screen_stack.toSlice()[screen_stack.len - 1];

    current_screen.update(current_time, delta);

    // Update food
    if (!snake.dead) {
        if (food_pos) |pos| {
            // If the head is close to the fruit
            if (pos.sub(&snake.head_segment.pos).magnitude() < (SNAKE_SEGMENT_LENGTH + 20) / 2) {
                // Eat it
                food_pos = null;
                snake.addSegment();
            }
        } else {
            food_pos = .{
                .x = LEVEL_OFFSET_X + random.random.float(f32) * LEVEL_WIDTH - LEVEL_WIDTH / 2,
                .y = LEVEL_OFFSET_Y + random.random.float(f32) * LEVEL_HEIGHT - LEVEL_HEIGHT / 2,
            };
        }
    }

    // Update target angle from key inputs
    var target_head_dir_vec: Vec2f = .{ .x = 0, .y = 0 };
    if (inputs.north) target_head_dir_vec.y -= 1;
    if (inputs.south) target_head_dir_vec.y += 1;
    if (inputs.east) target_head_dir_vec.x += 1;
    if (inputs.west) target_head_dir_vec.x -= 1;
    if (target_head_dir_vec.x != 0 or target_head_dir_vec.y != 0) {
        snake.target_head_dir = std.math.atan2(f32, target_head_dir_vec.y, target_head_dir_vec.x);
    }

    snake.update(current_time, delta);
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

    renderer.pushRect(.{ .x = LEVEL_OFFSET_X, .y = LEVEL_OFFSET_Y }, .{ .x = LEVEL_WIDTH, .y = LEVEL_HEIGHT }, LEVEL_COLOR, 0);

    snake.render(&renderer, alpha);

    if (food_pos) |pos| {
        renderer.pushRect(pos, .{ .x = FOOD_WIDTH, .y = FOOD_HEIGHT }, FOOD_COLOR, 0);
    }

    current_screen.render(&renderer, alpha);

    renderer.flush();
    platform.renderPresent();
}

test "" {
    std.meta.refAllDecls(ring_buffer);
}
