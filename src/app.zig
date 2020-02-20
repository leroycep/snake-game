const std = @import("std");
const platform = @import("platform.zig");
usingnamespace @import("constants.zig");
const Vec2f = platform.Vec2f;

var goto_pos = Vec2f{ .x = 0, .y = 0 };
var head_dir_rads: f32 = 0;
var head_pos = Vec2f{ .x = 100, .y = 100 };
var segments = [_]?Vec2f{null} ** MAX_SEGMENTS;
var next_segment_idx: usize = 0;
var tail_pos = Vec2f{ .x = 100, .y = 100 };
var frames: usize = 0;

pub fn onInit() void {
    addSegment();
}

pub fn onEvent(event: platform.Event) void {
    switch (event) {
        .Quit => platform.quit(),
        .KeyDown => |ev| if (ev.scancode == .ESCAPE) {
            platform.quit();
        },
        .MouseMotion => |mouse_pos| {
            goto_pos = Vec2f{
                .x = @intToFloat(f32, mouse_pos.x),
                .y = @intToFloat(f32, mouse_pos.y),
            };
        },
        else => {},
    }
}

pub fn update(current_time: f64, delta: f64) void {
    // Move head
    const head_offset = goto_pos.sub(&head_pos);
    const head_speed = @floatCast(f32, SNAKE_SPEED * delta);
    if (head_offset.magnitude() > head_speed) {
        const head_dir = head_offset.normalize();
        const head_movement = head_dir.scalMul(head_speed);

        head_dir_rads = std.math.atan2(f32, head_dir.x, head_dir.y);
        head_pos = head_pos.add(&head_movement);
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
    platform.fillRect2(@floatToInt(i32, head_pos.x), @floatToInt(i32, head_pos.y), 50, 50, head_dir_rads);

    var idx: usize = 0;
    while (segments[idx]) |segment| {
        platform.fillRect(@floatToInt(i32, segment.x) - 25, @floatToInt(i32, segment.y) - 15, SNAKE_SEGMENT_LENGTH, 30);
        idx += 1;
    }
    platform.fillRect(@floatToInt(i32, tail_pos.x - (SNAKE_TAIL_LENGTH / 2)), @floatToInt(i32, tail_pos.y - 10), SNAKE_TAIL_LENGTH, 20);
}

fn addSegment() void {
    if (next_segment_idx == segments.len) {
        platform.warn("Ran out of space for snake segments\n", .{});
        return;
    }
    segments[next_segment_idx] = tail_pos;
}
