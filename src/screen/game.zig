const std = @import("std");
const screen = @import("../screen.zig");
const Screen = screen.Screen;
const platform = @import("../platform.zig");
const Vec2f = platform.Vec2f;
const Renderer = @import("../renderer.zig").Renderer;
const game = @import("../game.zig");
usingnamespace @import("../constants.zig");

/// Keep track of D-Pad status
const Inputs = struct {
    north: bool = false,
    east: bool = false,
    south: bool = false,
    west: bool = false,
};

pub const Game = struct {
    alloc: *std.mem.Allocator,
    screen: Screen,

    random: std.rand.DefaultPrng,
    inputs: Inputs = Inputs{},

    snake: game.Snake,
    food_pos: ?Vec2f = null,

    pub fn init(alloc: *std.mem.Allocator) !*@This() {
        const self = try alloc.create(@This());
        self.* = .{
            .alloc = alloc,
            .screen = .{
                .onEventFn = onEvent,
                .updateFn = update,
                .renderFn = render,
            },

            .random = std.rand.DefaultPrng.init(1337),
            .snake = try game.Snake.init(alloc),
        };
        self.snake.addSegment();
        return self;
    }

    pub fn onEvent(screenPtr: *Screen, event: platform.Event) void {
        const self = @fieldParentPtr(@This(), "screen", screenPtr);
        switch (event) {
            .Quit => platform.quit(),
            .ScreenResized => |screen_size| platform.glViewport(0, 0, screen_size.x, screen_size.y),
            .KeyDown => |ev| switch (ev.scancode) {
                .ESCAPE => platform.quit(),
                .UP => self.inputs.north = true,
                .RIGHT => self.inputs.east = true,
                .DOWN => self.inputs.south = true,
                .LEFT => self.inputs.west = true,
                else => {},
            },
            .KeyUp => |ev| switch (ev.scancode) {
                .UP => self.inputs.north = false,
                .RIGHT => self.inputs.east = false,
                .DOWN => self.inputs.south = false,
                .LEFT => self.inputs.west = false,
                else => {},
            },
            else => {},
        }
    }

    pub fn update(screenPtr: *Screen, time: f64, delta: f64) void {
        const self = @fieldParentPtr(@This(), "screen", screenPtr);

        // Update food
        if (!self.snake.dead) {
            if (self.food_pos) |pos| {
                // If the head is close to the fruit
                if (pos.sub(&self.snake.head_segment.pos).magnitude() < (SNAKE_SEGMENT_LENGTH + 20) / 2) {
                    // Eat it
                    self.food_pos = null;
                    self.snake.addSegment();
                }
            } else {
                self.food_pos = .{
                    .x = LEVEL_OFFSET_X + self.random.random.float(f32) * LEVEL_WIDTH - LEVEL_WIDTH / 2,
                    .y = LEVEL_OFFSET_Y + self.random.random.float(f32) * LEVEL_HEIGHT - LEVEL_HEIGHT / 2,
                };
            }
        }

        // Update target angle from key inputs
        var target_head_dir_vec: Vec2f = .{ .x = 0, .y = 0 };
        if (self.inputs.north) target_head_dir_vec.y -= 1;
        if (self.inputs.south) target_head_dir_vec.y += 1;
        if (self.inputs.east) target_head_dir_vec.x += 1;
        if (self.inputs.west) target_head_dir_vec.x -= 1;
        if (target_head_dir_vec.x != 0 or target_head_dir_vec.y != 0) {
            self.snake.target_head_dir = std.math.atan2(f32, target_head_dir_vec.y, target_head_dir_vec.x);
        }

        self.snake.update(time, delta);
    }

    pub fn render(screenPtr: *const Screen, renderer: *Renderer, alpha: f64) void {
        const self = @fieldParentPtr(@This(), "screen", screenPtr);

        renderer.pushRect(.{ .x = LEVEL_OFFSET_X, .y = LEVEL_OFFSET_Y }, .{ .x = LEVEL_WIDTH, .y = LEVEL_HEIGHT }, LEVEL_COLOR, 0);

        self.snake.render(renderer, alpha);

        if (self.food_pos) |pos| {
            renderer.pushRect(pos, .{ .x = FOOD_WIDTH, .y = FOOD_HEIGHT }, FOOD_COLOR, 0);
        }
    }
};
