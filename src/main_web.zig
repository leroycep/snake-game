const app = @import("app.zig");

export fn onInit() void {
    app.onInit();
}

export fn update(current_time: f64, delta: f64) void {
    app.update(current_time, delta);
}

export fn render(alpha: f64) void {
    app.render(alpha);
}
