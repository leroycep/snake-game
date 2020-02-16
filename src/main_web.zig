const platform = @import("platform.zig");

var x: i32 = 10;

export fn onInit() void {
    const message = "Hello, world!";
    platform.consoleLogS(message, message.len);
}

export fn update(current_time: f64, delta: f64) void {
    x += @floatToInt(i32, 640 * delta);
}

export fn render(alpha: f64) void {
    const w = platform.getScreenW();
    const h = platform.getScreenW();
    platform.clearRect(0, 0, w, h);

    platform.setFillStyle(100, 0, 0);
    platform.fillRect(x, 50, 50, 50);
}
