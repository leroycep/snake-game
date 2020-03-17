pub const MainMenu = @import("screen/main_menu.zig").MainMenu;
const Renderer = @import("renderer.zig").Renderer;

pub const Screen = struct {
    startFn: ?fn (*@This()) void = null,
    updateFn: fn (*@This(), time: f64, delta: f64) void,
    renderFn: fn (*const @This(), renderer: *Renderer, alpha: f64) void,

    pub fn start(self: *@This()) void {
        if (self.startFn) |startFn| {
            startFn(self);
        }
    }

    pub fn update(self: *@This(), time: f64, delta: f64) void {
        self.updateFn(self, time, delta);
    }

    pub fn render(self: *const @This(), renderer: *Renderer, alpha: f64) void {
        self.renderFn(self, renderer, alpha);
    }
};
