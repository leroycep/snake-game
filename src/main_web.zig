const app = @import("app.zig");
const constants = @import("constants.zig");
const platform = @import("platform.zig");

export const SCANCODE_ESCAPE = @enumToInt(platform.Scancode.ESCAPE);
export const SCANCODE_W = @enumToInt(platform.Scancode.W);
export const SCANCODE_A = @enumToInt(platform.Scancode.A);
export const SCANCODE_S = @enumToInt(platform.Scancode.S);
export const SCANCODE_D = @enumToInt(platform.Scancode.D);
export const SCANCODE_Z = @enumToInt(platform.Scancode.Z);
export const SCANCODE_LEFT = @enumToInt(platform.Scancode.LEFT);
export const SCANCODE_RIGHT = @enumToInt(platform.Scancode.RIGHT);
export const SCANCODE_UP = @enumToInt(platform.Scancode.UP);
export const SCANCODE_DOWN = @enumToInt(platform.Scancode.DOWN);

export const MAX_DELTA_SECONDS = constants.MAX_DELTA_SECONDS;
export const TICK_DELTA_SECONDS = constants.TICK_DELTA_SECONDS;

var context: platform.Context = undefined;

export fn onInit() void {
    context = platform.Context{
        .renderer = platform.Renderer.init(),
    };
    app.onInit(&context);
}

export fn onMouseMove(x: i32, y: i32) void {
    app.onEvent(&context, .{
        .MouseMotion = .{
            .x = x,
            .y = y,
        },
    });
}

export fn onKeyDown(scancode: u16) void {
    app.onEvent(&context, .{
        .KeyDown = .{
            .scancode = @intToEnum(platform.Scancode, scancode),
        },
    });
}

export fn onKeyUp(scancode: u16) void {
    app.onEvent(&context, .{
        .KeyUp = .{
            .scancode = @intToEnum(platform.Scancode, scancode),
        },
    });
}

export fn onResize() void {
    app.onEvent(&context, .{
        .ScreenResized = platform.getScreenSize(),
    });
}

export fn onCustomEvent(eventId: u32) void {
    app.onEvent(&context, .{
        .Custom = eventId,
    });
}

export fn update(current_time: f64, delta: f64) void {
    app.update(&context, current_time, delta);
}

export fn render(alpha: f64) void {
    app.render(&context, alpha);
}
