const app = @import("app.zig");
const constants = @import("constants.zig");

export const MAX_DELTA_SECONDS = constants.MAX_DELTA_SECONDS;
export const TICK_DELTA_SECONDS = constants.TICK_DELTA_SECONDS;

export fn onInit() void {
    app.onInit();
}

export fn onMouseMove(x: i32, y: i32) void {
    app.onEvent(.{
        .MouseMotion = .{
            .x = x,
            .y = y,
        },
    });
}

export fn update(current_time: f64, delta: f64) void {
    app.update(current_time, delta);
}

export fn render(alpha: f64) void {
    app.render(alpha);
}
