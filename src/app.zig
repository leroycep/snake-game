const std = @import("std");
const platform = @import("platform.zig");
const Vec2 = platform.Vec2;

var head_pos = Vec2{ .x = 100, .y = 100 };

pub fn onInit() void {
    platform.log("Hello, world!");
}

pub fn onEvent(event: platform.Event) void {
    switch (event) {
        .Quit => platform.quit = true,
        .KeyDown => |ev| if (ev.scancode == .ESCAPE) {
            platform.quit = true;
        },
        else => {},
    }
}

pub fn update(current_time: f64, delta: f64) void {}

pub fn render(alpha: f64) void {
    const screen_size = platform.getScreenSize();
    platform.clearRect(0, 0, screen_size.x, screen_size.y);

    platform.setFillStyle(100, 0, 0);
    platform.fillRect(head_pos.x, head_pos.y-25, 50, 50);
    platform.fillRect(head_pos.x-50, head_pos.y-15, 50, 30);
    platform.fillRect(head_pos.x-50-30, head_pos.y-10, 30, 20);
}
