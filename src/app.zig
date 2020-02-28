const std = @import("std");
const platform = @import("platform.zig");
usingnamespace @import("constants.zig");
const Vec2f = platform.Vec2f;
const pi = std.math.pi;
const Renderer = @import("renderer.zig").Renderer;
const physics = @import("physics.zig");

var renderer: Renderer = undefined;

var camera_pos = Vec2f{ .x = 0, .y = 0 };
var target_head_dir: f32 = 0;
var head_segment = Segment{
    .pos = Vec2f{ .x = 100, .y = 100 },
    .size = Vec2f{ .x = SNAKE_SEGMENT_LENGTH, .y = SNAKE_HEAD_WIDTH },
    .dir = 0,
};
var head_body = physics.RigidCircle{
    .radius = SNAKE_HEAD_WIDTH / 2,
    .pos = .{ .x = 100, .y = 100 },
    .vel = .{ .x = 0, .y = 0 },
    .restitution = SNAKE_SEGMENT_RESTITUTION,
    .inv_mass = SNAKE_SEGMENT_INV_MASS,
};

var segments = [_]?Segment{null} ** MAX_SEGMENTS;
var segment_bodies = [_]?physics.RigidCircle{null} ** MAX_SEGMENTS;
var next_segment_idx: usize = 0;
var tail_segment = Segment{
    .pos = Vec2f{ .x = 100, .y = 100 },
    .size = Vec2f{ .x = SNAKE_TAIL_LENGTH, .y = SNAKE_TAIL_WIDTH },
    .dir = 0,
};
var frames: usize = 0;

var random: std.rand.DefaultPrng = undefined;
var food_pos: ?Vec2f = null;

var columns = [_]physics.RigidCircle{
    .{
        .radius = 20,
        .pos = .{ .x = 300, .y = 400 },
        .vel = .{ .x = 0, .y = 0 },
        .restitution = 0.2,
        .inv_mass = 0,
    },
    .{
        .radius = 20,
        .pos = .{ .x = 250, .y = 350 },
        .vel = .{ .x = 0, .y = 0 },
        .restitution = 0.2,
        .inv_mass = 0,
    },
    .{
        .radius = 20,
        .pos = .{ .x = 350, .y = 350 },
        .vel = .{ .x = 0, .y = 0 },
        .restitution = 0.2,
        .inv_mass = 0,
    },
};

var inputs = Inputs{};

/// Keep track of D-Pad status
const Inputs = struct {
    north: bool = false,
    east: bool = false,
    south: bool = false,
    west: bool = false,
};

const Segment = struct {
    pos: Vec2f,
    size: Vec2f,

    /// In radians
    dir: f32,

    pub fn render(self: *const @This(), render_buffer: *Renderer, color: platform.Color) void {
        render_buffer.pushRect(self.pos, self.size, color, self.dir);
    }
};

pub fn onInit() void {
    renderer = Renderer.init();

    var i: usize = 0;
    while (i < 1) : (i += 1) {
        addSegment();
    }

    random = std.rand.DefaultPrng.init(1337);
}

pub fn onEvent(event: platform.Event) void {
    switch (event) {
        .Quit => platform.quit(),
        .ScreenResized => |screen_size| platform.glViewport(0, 0, screen_size.x, screen_size.y),
        .KeyDown => |ev| switch (ev.scancode) {
            .ESCAPE => platform.quit(),
            .UP => inputs.north = true,
            .RIGHT => inputs.east = true,
            .DOWN => inputs.south = true,
            .LEFT => inputs.west = true,
            else => {},
        },
        .KeyUp => |ev| switch (ev.scancode) {
            .UP => inputs.north = false,
            .RIGHT => inputs.east = false,
            .DOWN => inputs.south = false,
            .LEFT => inputs.west = false,
            else => {},
        },
        else => {},
    }
}

pub fn update(current_time: f64, delta: f64) void {
    // Update food
    if (food_pos) |pos| {
        // If the head is close to the fruit
        if (pos.sub(&head_segment.pos).magnitude() < (SNAKE_SEGMENT_LENGTH + 20) / 2) {
            // Eat it
            food_pos = null;
            addSegment();
        }
    } else {
        food_pos = .{
            .x = LEVEL_OFFSET_X + random.random.float(f32) * LEVEL_WIDTH - LEVEL_WIDTH / 2,
            .y = LEVEL_OFFSET_Y + random.random.float(f32) * LEVEL_HEIGHT - LEVEL_HEIGHT / 2,
        };
    }

    // Update target angle from key inputs
    var target_head_dir_vec: Vec2f = .{ .x = 0, .y = 0 };
    if (inputs.north) target_head_dir_vec.y -= 1;
    if (inputs.south) target_head_dir_vec.y += 1;
    if (inputs.east) target_head_dir_vec.x += 1;
    if (inputs.west) target_head_dir_vec.x -= 1;
    if (target_head_dir_vec.x != 0 or target_head_dir_vec.y != 0) {
        target_head_dir = std.math.atan2(f32, target_head_dir_vec.y, target_head_dir_vec.x);
    }

    // Turn head
    const angle_difference = @mod(((target_head_dir - head_segment.dir) + pi), 2 * pi) - pi;
    const angle_change = std.math.clamp(angle_difference, @floatCast(f32, -SNAKE_TURN_SPEED * delta), @floatCast(f32, SNAKE_TURN_SPEED * delta));
    head_segment.dir += angle_change;
    if (head_segment.dir >= 2 * pi) {
        head_segment.dir -= 2 * pi;
    } else if (head_segment.dir < 0) {
        head_segment.dir += 2 * pi;
    }

    // Move head
    const target_vel = Vec2f.unitFromRad(head_segment.dir).scalMul(@floatCast(f32, SNAKE_SPEED));
    const vel_diff = target_vel.sub(&head_body.vel);
    head_body.vel = head_body.vel.add(&vel_diff);

    // Make camera follow snake head
    const screen_size = Vec2f{ .x = VIEWPORT_WIDTH, .y = VIEWPORT_HEIGHT };
    camera_pos = head_segment.pos.sub(&screen_size.scalMul(0.5));

    // Make segments trail head
    var segment_idx: usize = 0;
    var prev_segment = &head_segment;
    var prev_body = &head_body;
    while (prev_segment != &tail_segment) : (segment_idx += 1) {
        var cur_segment = if (segments[segment_idx] != null) &segments[segment_idx].? else &tail_segment;

        if (segment_bodies[segment_idx]) |*cur_body| {
            physics.spring_constraint(cur_body, prev_body, SNAKE_SEGMENT_LENGTH, 0.001);
            for (columns) |*column| {
                if (cur_body.collsion(column)) |manifold| {
                    manifold.resolve_collision();
                    manifold.position_correction();
                }
            }
            prev_body = cur_body;
        } else {
            // Update the tail
            const dist_from_prev: f32 = SNAKE_TAIL_LENGTH / 2 + SNAKE_SEGMENT_LENGTH / 2;

            var vec_from_prev = cur_segment.pos.sub(&prev_segment.pos);
            if (vec_from_prev.magnitude() > dist_from_prev) {
                const dir_from_prev = vec_from_prev.normalize();
                const new_offset_from_prev = dir_from_prev.scalMul(dist_from_prev);

                cur_segment.dir = std.math.atan2(f32, dir_from_prev.y, dir_from_prev.x);
                cur_segment.pos = prev_segment.pos.add(&new_offset_from_prev);
            }
        }

        prev_segment = cur_segment;
    }

    // Update head physics body
    head_body.pos = head_body.pos.add(&head_body.vel.scalMul(@floatCast(f32, delta)));
    head_segment.pos = head_body.pos;

    // Update physics
    segment_idx = 0;
    while (segments[segment_idx] != null) : (segment_idx += 1) {
        var segment = &segments[segment_idx].?;
        var body = &segment_bodies[segment_idx].?;

        body.pos = body.pos.add(&body.vel.scalMul(@floatCast(f32, delta)));
        segment.dir = std.math.atan2(f32, body.vel.y, body.vel.x);
        segment.pos = body.pos;

        // Apply friction
        body.vel = body.vel.scalMul(0.95);
    }

    frames += 1;
}

fn mulMat4(a: []const f32, b: []const f32) [16]f32 {
    std.debug.assert(a.len == 16);
    std.debug.assert(b.len == 16);

    var c: [16]f32 = undefined;
    comptime var i: usize = 0;
    inline while (i < 4) : (i += 1) {
        comptime var j: usize = 0;
        inline while (j < 4) : (j += 1) {
            c[i * 4 + j] = 0;
            comptime var k: usize = 0;
            inline while (k < 4) : (k += 1) {
                c[i * 4 + j] += a[i * 4 + k] * b[k * 4 + j];
            }
        }
    }
    return c;
}

pub fn render(alpha: f64) void {
    renderer.setTranslation(camera_pos);
    renderer.begin();

    renderer.pushRect(.{ .x = LEVEL_OFFSET_X, .y = LEVEL_OFFSET_Y }, .{ .x = LEVEL_WIDTH, .y = LEVEL_HEIGHT }, LEVEL_COLOR, 0);

    for (columns) |column| {
        renderer.pushRect(column.pos, .{ .x = column.radius * 2, .y = column.radius * 2 }, .{ .r = 0xFF, .g = 0x00, .b = 0xFF }, 0);
    }

    head_segment.render(&renderer, SEGMENT_COLORS[0]);

    var idx: usize = 0;
    while (segments[idx]) |segment| {
        segment.render(&renderer, SEGMENT_COLORS[(idx + 1) % SEGMENT_COLORS.len]);
        idx += 1;
    }
    tail_segment.render(&renderer, SEGMENT_COLORS[(idx + 1) % SEGMENT_COLORS.len]);

    if (food_pos) |pos| {
        renderer.pushRect(pos, .{ .x = FOOD_WIDTH, .y = FOOD_HEIGHT }, FOOD_COLOR, 0);
    }

    renderer.flush();
    platform.renderPresent();
}

fn addSegment() void {
    if (next_segment_idx == segments.len) {
        platform.warn("Ran out of space for snake segments\n", .{});
        return;
    }
    segments[next_segment_idx] = .{
        .pos = tail_segment.pos,
        .dir = tail_segment.dir,
        .size = .{ .x = SNAKE_SEGMENT_LENGTH, .y = SNAKE_SEGMENT_WIDTH },
    };
    segment_bodies[next_segment_idx] = .{
        .radius = segments[next_segment_idx].?.size.y / 2.0,
        .pos = segments[next_segment_idx].?.pos,
        .vel = .{ .x = 0, .y = 0 },
        .restitution = SNAKE_SEGMENT_RESTITUTION,
        .inv_mass = SNAKE_SEGMENT_INV_MASS,
    };
    next_segment_idx += 1;
}
