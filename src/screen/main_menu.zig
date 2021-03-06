const std = @import("std");
usingnamespace @import("../constants.zig");
const screen = @import("../screen.zig");
const Screen = screen.Screen;
const platform = @import("../platform.zig");
const Context = platform.Context;
const Component = platform.components.Component;
const Layout = platform.components.Layout;
const Events = platform.components.Events;
const utils = @import("../utils.zig");
const Option = utils.Option;

const NORMAL_PLAY_CLICK = 1;
const NORMAL_PLAY_HOVER = 2;
const NORMAL_PLAY_EVENTS = Events{
    .click = NORMAL_PLAY_CLICK,
    .hover = NORMAL_PLAY_HOVER,
};
const CASUAL_PLAY_CLICK = 3;
const CASUAL_PLAY_HOVER = 4;
const CASUAL_PLAY_EVENTS = Events{
    .click = CASUAL_PLAY_CLICK,
    .hover = CASUAL_PLAY_HOVER,
};
const HIGHSCORES_CLICK = 5;
const HIGHSCORES_HOVER = 6;
const HIGHSCORES_EVENTS = Events{
    .click = HIGHSCORES_CLICK,
    .hover = HIGHSCORES_HOVER,
};

const Desc = enum {
    NormalPlay,
    CasualPlay,
    Highscores,

    pub fn getText(self: @This()) []const u8 {
        return switch (self) {
            .NormalPlay => {
                return
                    \\ Eat as much fruit as you can, but make sure not to hit your tail!
                ;
            },
            .CasualPlay => {
                return
                    \\ Don't like worrying about your score, but love to see the snake
                    \\ get longer? In this mode you'll pass harmlessly over yourself,
                    \\ and no score will be recorded.
                ;
            },
            .Highscores => {
                return
                    \\ See the highscores (scores are local to this machine).
                ;
            },
        };
    }
};

pub const MainMenu = struct {
    alloc: *std.mem.Allocator,
    screen: Screen,

    dirty: bool = true,
    play_pressed: bool = false,
    casual_play_pressed: bool = false,
    desc: Option(Desc) = Option(Desc){ .None = {} },
    dependencies: utils.Dependencies(Option(Desc)),

    pub fn init(alloc: *std.mem.Allocator) !*@This() {
        const self = try alloc.create(@This());
        self.* = .{
            .alloc = alloc,
            .dependencies = utils.Dependencies(Option(Desc)).init(),
            .screen = .{
                .onEventFn = onEvent,
                .updateFn = update,
                .renderFn = render,
                .stopFn = stop,
            },
        };
        return self;
    }

    pub fn onEvent(screenPtr: *Screen, context: *Context, event: platform.Event) void {
        const self = @fieldParentPtr(@This(), "screen", screenPtr);
        switch (event) {
            .Quit => platform.quit(),
            .ScreenResized => |screen_size| platform.glViewport(0, 0, screen_size.x, screen_size.y),
            .KeyDown => |ev| switch (ev.scancode) {
                .ESCAPE => platform.quit(),
                .Z => self.play_pressed = true,
                else => {},
            },
            .Custom => |eventId| switch (eventId) {
                NORMAL_PLAY_CLICK => self.play_pressed = true,
                NORMAL_PLAY_HOVER => self.desc = .{ .Some = .NormalPlay },
                CASUAL_PLAY_CLICK => self.casual_play_pressed = true,
                CASUAL_PLAY_HOVER => self.desc = .{ .Some = .CasualPlay },
                HIGHSCORES_HOVER => self.desc = .{ .Some = .Highscores },
                else => platform.warn("Unknown event id: {}\n", .{eventId}),
            },
            else => {},
        }
    }

    pub fn update(screenPtr: *Screen, context: *Context, time: f64, delta: f64) ?screen.Transition {
        const self = @fieldParentPtr(@This(), "screen", screenPtr);

        if (self.play_pressed) {
            const game = screen.Game.init(self.alloc, false) catch unreachable;
            return screen.Transition{ .Replace = &game.screen };
        }

        if (self.casual_play_pressed) {
            const game = screen.Game.init(self.alloc, true) catch unreachable;
            return screen.Transition{ .Replace = &game.screen };
        }

        return null;
    }

    pub fn render(screenPtr: *Screen, context: *Context, alpha: f64) void {
        const self = @fieldParentPtr(@This(), "screen", screenPtr);

        const screen_size = platform.Vec2f.fromVeci(platform.getScreenSize());
        context.renderer.pushRect(screen_size.scalMul(0.5), screen_size, LEVEL_COLOR, 0);

        if (self.dependencies.is_changed(self.desc)) {
            self.update_gui(context);
            self.dependencies.update(self.desc);
        }
    }

    fn update_gui(self: *@This(), context: *Context) void {
        const text = platform.components.text;
        const box = platform.components.box;
        const button = platform.components.button;

        const description = switch (self.desc) {
            .Some => |desc| desc.getText(),
            .None => "",
        };

        const grid = Layout.grid(.{
            .row = &[_]u32{ 1, 1 },
            .column = &[_]u32{ 1, 3 },
            .areas = &[_][]const usize{
                &[_]usize{ 0, 0 },
                &[_]usize{ 2, 1 },
            },
        });

        const button_grid = Layout.grid(.{
            .column = &[_]u32{ 1, 1, 1 },
        });
        const centered = Layout.flex(.Horizontal);

        const components = box(grid, &[_]Component{
            box(centered, &[_]Component{text("Snake Game")}),
            box(centered, &[_]Component{text(description)}),
            box(button_grid, &[_]Component{
                button("Normal Play", NORMAL_PLAY_EVENTS),
                button("Casual Play", CASUAL_PLAY_EVENTS),
                button("Highscores", HIGHSCORES_EVENTS),
            }),
        });
        context.updateComponent(&components) catch unreachable;
    }

    pub fn stop(screenPtr: *Screen, context: *Context) void {
        const self = @fieldParentPtr(@This(), "screen", screenPtr);
        context.clearComponent();
    }
};
