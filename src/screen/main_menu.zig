const std = @import("std");
const screen = @import("../screen.zig");
const Screen = screen.Screen;
const platform = @import("../platform.zig");
const Renderer = @import("../renderer.zig").Renderer;
const ComponentRenderer = platform.components.ComponentRenderer;
const Component = platform.components.Component;

const NORMAL_PLAY_PRESSED = 1;
const HOVER_NORMAL_PLAY = 2;

const Desc = enum {
    NormalPlay,
};

pub const MainMenu = struct {
    alloc: *std.mem.Allocator,
    screen: Screen,

    dirty: bool = true,
    component_renderer: ComponentRenderer,
    play_pressed: bool = false,
    desc: ?Desc = null,

    pub fn init(alloc: *std.mem.Allocator) !*@This() {
        const self = try alloc.create(@This());
        self.* = .{
            .alloc = alloc,
            .component_renderer = try ComponentRenderer.init(alloc),
            .screen = .{
                .onEventFn = onEvent,
                .updateFn = update,
                .renderFn = render,
                .stopFn = stop,
            },
        };
        return self;
    }

    pub fn onEvent(screenPtr: *Screen, event: platform.Event) void {
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
                NORMAL_PLAY_PRESSED => self.play_pressed = true,
                HOVER_NORMAL_PLAY => {
                    self.desc = .NormalPlay;
                    self.dirty = true;
                },
                else => platform.warn("Unknown event id: {}\n", .{eventId}),
            },
            else => {},
        }
    }

    pub fn update(screenPtr: *Screen, time: f64, delta: f64) ?screen.Transition {
        const self = @fieldParentPtr(@This(), "screen", screenPtr);

        if (self.play_pressed) {
            const game = screen.Game.init(self.alloc) catch unreachable;
            return screen.Transition{ .Replace = &game.screen };
        }

        return null;
    }

    pub fn render(screenPtr: *Screen, renderer: *Renderer, alpha: f64) void {
        const self = @fieldParentPtr(@This(), "screen", screenPtr);

        const text = platform.components.text;
        const box = platform.components.box;
        const vbox = platform.components.vbox;
        const button = platform.components.button;

        if (!self.dirty) return;

        var description: []const u8 = undefined;
        if (self.desc) |desc| {
            description = switch (desc) {
                .NormalPlay => "Eat as much fruit as you can, but make sure not to hit your tail!",
            };
        } else {
            description = "";
        }

        self.component_renderer.render(&vbox(
            &[_]Component{
                text("Snake Game"),
                box(.{ .grow = 1 }, &[_]Component{
                    vbox(&[_]Component{
                        button("Normal Play", .{ .click = NORMAL_PLAY_PRESSED, .hover = HOVER_NORMAL_PLAY }),
                        button("Casual Play", .{}),
                        button("Highscores", .{}),
                    }),
                    text(description),
                }),
            },
        )) catch unreachable;

        self.dirty = false;
    }

    pub fn stop(screenPtr: *Screen) void {
        const self = @fieldParentPtr(@This(), "screen", screenPtr);
        platform.clearComponents();
    }
};
