const platform = @import("platform.zig");

var x: i32 = 10;

export fn onInit() void {
    platform.log("Hello, world!");
}

export fn update(current_time: f64, delta: f64) void {
    x += @floatToInt(i32, 640 * delta);
}

export fn render(alpha: f64) void {
    const screen_size = platform.getScreenSize();
    platform.clearRect(0, 0, screen_size.x, screen_size.y);

    platform.setFillStyle(100, 0, 0);
    platform.fillRect(x, 50, 50, 50);
}
