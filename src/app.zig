const std = @import("std");
const platform = @import("platform.zig");
usingnamespace @import("constants.zig");
const Vec2f = platform.Vec2f;

var head_pos = Vec2f{ .x = 100, .y = 100 };
var segments = [_]?Vec2f{null} ** MAX_SEGMENTS;
var next_segment_idx: usize = 0;
var tail_pos = Vec2f{ .x = 100, .y = 100 };
var frames: usize = 0;

pub fn onInit() void {
    platform.log("Hello, world!");
    addSegment();
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

pub fn update(current_time: f64, delta: f64) void {
    // Move head
    head_pos.x += @floatCast(f32, SNAKE_SPEED * delta);
    if (head_pos.x > @intToFloat(f32, platform.getScreenSize().x)) {
        head_pos.x = 0;
    }

    // Make segments trail head
    var segment_idx: usize = 0;
    var prev_segment = &head_pos;
    while (prev_segment != &tail_pos) : (segment_idx += 1) {
        var cur_segment = if (segments[segment_idx] != null) &segments[segment_idx].? else &tail_pos;

        var dist_from_prev: f32 = undefined;
        if (cur_segment != &tail_pos) {
            dist_from_prev = SNAKE_SEGMENT_LENGTH;
        } else {
            dist_from_prev = SNAKE_TAIL_LENGTH / 2 + SNAKE_SEGMENT_LENGTH / 2;
        }

        var vec_from_prev = Vec2f{
            .x = cur_segment.x - prev_segment.x,
            .y = cur_segment.y - prev_segment.y,
        };
        if (vec_from_prev.magnitude() > dist_from_prev) {
            const dir_from_prev = vec_from_prev.normalize();
            const new_offset_from_prev = dir_from_prev.scalMul(dist_from_prev);
            cur_segment.* = prev_segment.add(&new_offset_from_prev);
        }

        prev_segment = cur_segment;
    }

    frames += 1;
}

pub fn render(alpha: f64) void {
    const screen_size = platform.getScreenSize();
    platform.clearRect(0, 0, screen_size.x, screen_size.y);

    platform.setFillStyle(100, 0, 0);
    platform.fillRect(@floatToInt(i32, head_pos.x - 25), @floatToInt(i32, head_pos.y) - 25, 50, 50);

    var idx: usize = 0;
    while (segments[idx]) |segment| {
        platform.fillRect(@floatToInt(i32, segment.x) - 25, @floatToInt(i32, segment.y) - 15, SNAKE_SEGMENT_LENGTH, 30);
        idx += 1;
    }
    platform.fillRect(@floatToInt(i32, tail_pos.x - (SNAKE_TAIL_LENGTH / 2)), @floatToInt(i32, tail_pos.y - 10), SNAKE_TAIL_LENGTH, 20);
}

fn addSegment() void {
    if (next_segment_idx == segments.len) {
        platform.log("Ran out of space for snake segments");
        return;
    }
    segments[next_segment_idx] = tail_pos;
}
