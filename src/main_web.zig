const platform = @import("platform.zig");

export fn onInit() void {
    const message = "Hello, world!";
    platform.consoleLogS(message, message.len);
    platform.setFillStyle(100, 0, 0);
    platform.fillRect(50, 50, 50, 50);
}
