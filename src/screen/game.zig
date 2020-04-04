const std = @import("std");
const screen = @import("../screen.zig");
const Screen = screen.Screen;
const platform = @import("../platform.zig");
const components = platform.components;
const Vec2f = platform.Vec2f;
const Context = platform.Context;
const Renderer = platform.Renderer;
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
    time: f64 = 0,
    score: u32 = 0,
    quit_pressed: bool = false,

    score_str: []const u8 = &[_]u8{},
    time_str: []const u8 = &[_]u8{},

    pub fn init(alloc: *std.mem.Allocator) !*@This() {
        const self = try alloc.create(@This());
        self.* = .{
            .alloc = alloc,
            .screen = .{
                .onEventFn = onEvent,
                .updateFn = update,
                .renderFn = render,
                .deinitFn = deinit,
            },

            .random = std.rand.DefaultPrng.init(platform.now()),
            .snake = try game.Snake.init(alloc),
        };
        self.snake.addSegment();
        return self;
    }

    pub fn onEvent(screenPtr: *Screen, context: *Context, event: platform.Event) void {
        const self = @fieldParentPtr(@This(), "screen", screenPtr);
        switch (event) {
            .Quit => platform.quit(),
            .ScreenResized => |screen_size| platform.glViewport(0, 0, screen_size.x, screen_size.y),
            .KeyDown => |ev| switch (ev.scancode) {
                .ESCAPE => self.quit_pressed = true,
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

    pub fn update(screenPtr: *Screen, context: *Context, time: f64, delta: f64) ?screen.Transition {
        const self = @fieldParentPtr(@This(), "screen", screenPtr);

        if (self.quit_pressed) {
            self.quit_pressed = false;
            const main_menu = screen.MainMenu.init(self.alloc) catch unreachable;
            return screen.Transition{ .Replace = &main_menu.screen };
        }

        // Update food
        if (!self.snake.dead) {
            if (self.food_pos) |pos| {
                // If the head is close to the fruit
                if (pos.sub(self.snake.head_segment.pos).magnitude() < (SNAKE_SEGMENT_LENGTH + 20) / 2) {
                    // Eat it
                    self.food_pos = null;
                    self.score += 1;
                    self.snake.addSegment();
                }
            } else {
                self.food_pos = .{
                    .x = LEVEL_OFFSET_X + self.random.random.float(f32) * LEVEL_WIDTH - LEVEL_WIDTH / 2,
                    .y = LEVEL_OFFSET_Y + self.random.random.float(f32) * LEVEL_HEIGHT - LEVEL_HEIGHT / 2,
                };
            }
            self.time += delta;
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

        return null;
    }

    pub fn render(screenPtr: *Screen, context: *Context, alpha: f64) void {
        const self = @fieldParentPtr(@This(), "screen", screenPtr);

        context.renderer.pushRect(.{ .x = LEVEL_OFFSET_X, .y = LEVEL_OFFSET_Y }, .{ .x = LEVEL_WIDTH, .y = LEVEL_HEIGHT }, LEVEL_COLOR, 0);

        self.snake.render(&context.renderer, alpha);

        if (self.food_pos) |pos| {
            context.renderer.pushRect(pos, .{ .x = FOOD_WIDTH, .y = FOOD_HEIGHT }, FOOD_COLOR, 0);
        }

        const Component = components.Component;
        const Layout = components.Layout;
        const box = components.box;
        const text = components.text;

        if (self.time_str.len != 0) {
            self.alloc.free(self.time_str);
        }
        if (self.score_str.len != 0) {
            self.alloc.free(self.score_str);
        }

        self.time_str = std.fmt.allocPrint(self.alloc, "Time: {d:.2}", .{self.time}) catch unreachable;
        self.score_str = std.fmt.allocPrint(self.alloc, "Score: {}", .{self.score}) catch unreachable;

        const component = box(Layout.flex(.Horizontal), &[_]Component{
            text(self.score_str),
            text(self.time_str),
        });
        context.updateComponent(&component) catch unreachable;
    }

    pub fn deinit(screenPtr: *Screen, context: *Context) void {
        const self = @fieldParentPtr(@This(), "screen", screenPtr);

        self.snake.deinit();
        self.alloc.destroy(self);
    }
};
