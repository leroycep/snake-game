const std = @import("std");
const screen = @import("../screen.zig");
const Screen = screen.Screen;
const platform = @import("../platform.zig");
const Renderer = @import("../renderer.zig").Renderer;

pub const MainMenu = struct {
    alloc: *std.mem.Allocator,
    screen: Screen,
    frame: u64,

    pub fn init(alloc: *std.mem.Allocator) !*@This() {
        const self = try alloc.create(@This());
        self.* = .{
            .alloc = alloc,
            .frame = 0,
            .screen = .{
                .updateFn = update,
                .renderFn = render,
            },
        };
        return self;
    }

    pub fn update(screenPtr: *Screen, time: f64, delta: f64) void {
        const self = @fieldParentPtr(@This(), "screen", screenPtr);
        self.frame += 1;
        if (self.frame % 60 == 0) {
            platform.warn("Update from main_menu!\n", .{});
        }
    }

    pub fn render(screenPtr: *const Screen, renderer: *Renderer, alpha: f64) void {
        const self = @fieldParentPtr(@This(), "screen", screenPtr);
        if (self.frame % 60 == 30) {
            platform.warn("Render from main_menu!\n", .{});
        }
    }
};
