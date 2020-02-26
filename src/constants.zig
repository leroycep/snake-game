const pi = @import("std").math.pi;
const Color = @import("platform.zig").Color;

pub const MAX_DELTA_SECONDS: f64 = 0.25;
pub const TICK_DELTA_SECONDS: f64 = 16.0 / 1000.0;

pub const VIEWPORT_WIDTH = 640;
pub const VIEWPORT_HEIGHT = 480;

pub const LEVEL_COLOR = Color{ .r = 0x58, .g = 0x83, .b = 0x30 };
pub const LEVEL_WIDTH = 1000;
pub const LEVEL_HEIGHT = 1000;

pub const MAX_SEGMENTS = 100;
pub const SNAKE_SPEED = 400; // pixels / second
pub const SNAKE_TURN_SPEED = 2.5 * pi; // radians a second

pub const SNAKE_HEAD_WIDTH = 25; // pixels
pub const SNAKE_SEGMENT_LENGTH = 25; // pixels
pub const SNAKE_SEGMENT_WIDTH = 15; // pixels
pub const SNAKE_TAIL_LENGTH = 15; // pixels
pub const SNAKE_TAIL_WIDTH = 10; // pixels

pub const FOOD_WIDTH = 10; // pixels
pub const FOOD_HEIGHT = 10; // pixels

pub const SEGMENT_COLORS = [_]Color{
    .{ .r = 0x31, .g = 0x31, .b = 0x31 },
    .{ .r = 0xFF, .g = 0x85, .b = 0x16 },
    .{ .r = 0xFB, .g = 0xF2, .b = 0x37 },
};
pub const FOOD_COLOR = Color{ .r = 0xFB, .g = 0x31, .b = 0x31 };
