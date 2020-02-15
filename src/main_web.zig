const platform = @import("platform.zig");

export fn onInit() void {
    const message = "Hello, world!";
    platform.consoleLogS(message, message.len);
}
