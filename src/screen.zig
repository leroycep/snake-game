const Renderer = @import("renderer.zig").Renderer;
const platform = @import("platform.zig");

pub const MainMenu = @import("screen/main_menu.zig").MainMenu;
pub const Game = @import("screen/game.zig").Game;

pub const TransitionTag = enum {
    Push,
    Replace,
    Pop,
};

pub const Transition = union(TransitionTag) {
    Push: *Screen,
    Replace: *Screen,
    Pop: void,
};

pub const Screen = struct {
    startFn: ?fn (*@This()) void = null,
    onEventFn: fn (*@This(), event: platform.Event) void,
    updateFn: fn (*@This(), time: f64, delta: f64) ?Transition,
    renderFn: fn (*@This(), renderer: *Renderer, alpha: f64) void,
    stopFn: ?fn (*@This()) void = null,
    deinitFn: ?fn (*@This()) void = null,

    pub fn start(self: *@This()) void {
        if (self.startFn) |startFn| {
            startFn(self);
        }
    }

    pub fn onEvent(self: *@This(), event: platform.Event) void {
        self.onEventFn(self, event);
    }

    pub fn update(self: *@This(), time: f64, delta: f64) ?Transition {
        return self.updateFn(self, time, delta);
    }

    pub fn render(self: *@This(), renderer: *Renderer, alpha: f64) void {
        self.renderFn(self, renderer, alpha);
    }

    pub fn stop(self: *@This()) void {
        if (self.stopFn) |stopFn| {
            stopFn(self);
        }
    }

    pub fn deinit(self: *@This()) void {
        if (self.deinitFn) |deinitFn| {
            deinitFn(self);
        }
    }
};
