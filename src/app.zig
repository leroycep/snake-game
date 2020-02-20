const std = @import("std");
const platform = @import("platform.zig");
usingnamespace @import("constants.zig");
const Vec2f = platform.Vec2f;

var goto_pos = Vec2f{ .x = 0, .y = 0 };
var head_segment = Segment{
    .pos = Vec2f{ .x = 100, .y = 100 },
    .dir = 0,
};
var segments = [_]?Segment{null} ** MAX_SEGMENTS;
var next_segment_idx: usize = 0;
var tail_segment = Segment{
    .pos = Vec2f{ .x = 100, .y = 100 },
    .dir = 0,
};
var frames: usize = 0;

const Segment = struct {
    pos: Vec2f,

    /// In radians
    dir: f32,
};

pub fn onInit() void {
    var i: usize = 0;
    while (i < 20) : (i += 1) {
        addSegment();
    }
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
    const head_offset = goto_pos.sub(&head_segment.pos);
    const head_speed = @floatCast(f32, SNAKE_SPEED * delta);
    if (head_offset.magnitude() > head_speed) {
        const head_dir = head_offset.normalize();
        const head_movement = head_dir.scalMul(head_speed);

        head_segment.dir = std.math.atan2(f32, head_dir.y, head_dir.x);
        head_segment.pos = head_segment.pos.add(&head_movement);
    }

    // Make segments trail head
    var segment_idx: usize = 0;
    var prev_segment = &head_segment;
    while (prev_segment != &tail_segment) : (segment_idx += 1) {
        var cur_segment = if (segments[segment_idx] != null) &segments[segment_idx].? else &tail_segment;

        var dist_from_prev: f32 = undefined;
        if (cur_segment != &tail_segment) {
            dist_from_prev = SNAKE_SEGMENT_LENGTH;
        } else {
            dist_from_prev = SNAKE_TAIL_LENGTH / 2 + SNAKE_SEGMENT_LENGTH / 2;
        }

        var vec_from_prev = cur_segment.pos.sub(&prev_segment.pos);
        if (vec_from_prev.magnitude() > dist_from_prev) {
            const dir_from_prev = vec_from_prev.normalize();
            const new_offset_from_prev = dir_from_prev.scalMul(dist_from_prev);

            cur_segment.dir = std.math.atan2(f32, dir_from_prev.y, dir_from_prev.x);
            cur_segment.pos = prev_segment.pos.add(&new_offset_from_prev);
        }

        prev_segment = cur_segment;
    }

    frames += 1;
}

pub fn render(alpha: f64) void {
    platform.glClearColor(1, 1, 1, 1);
    platform.glClear(platform.GL_COLOR_BUFFER_BIT);
    platform.renderPresent();
//    const screen_size = platform.getScreenSize();
//    platform.clearRect(0, 0, screen_size.x, screen_size.y);
//
//    platform.setFillStyle(SEGMENT_COLORS[0].r, SEGMENT_COLORS[0].g, SEGMENT_COLORS[0].b);
//    platform.fillRect2(@floatToInt(i32, head_segment.pos.x), @floatToInt(i32, head_segment.pos.y), 50, 50, head_segment.dir);
//
//    var idx: usize = 0;
//    while (segments[idx]) |segment| {
//        const color = SEGMENT_COLORS[(idx + 1) %  SEGMENT_COLORS.len];
//        platform.setFillStyle(color.r, color.g, color.b);
//
//        platform.fillRect2(@floatToInt(i32, segment.pos.x), @floatToInt(i32, segment.pos.y), SNAKE_SEGMENT_LENGTH, 30, segment.dir);
//        idx += 1;
//    }
//        const color = SEGMENT_COLORS[(idx + 1) %  SEGMENT_COLORS.len];
//    platform.setFillStyle(color.r, color.g, color.b);
//    platform.fillRect2(@floatToInt(i32, tail_segment.pos.x), @floatToInt(i32, tail_segment.pos.y), SNAKE_TAIL_LENGTH, 20, tail_segment.dir);
}

fn addSegment() void {
    if (next_segment_idx == segments.len) {
        platform.warn("Ran out of space for snake segments\n", .{});
        return;
    }
    segments[next_segment_idx] = tail_segment;
    next_segment_idx += 1;
}
