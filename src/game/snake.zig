const builtin = @import("builtin");
const std = @import("std");
usingnamespace @import("../constants.zig");
const platform = @import("../platform.zig");
const Vec2f = platform.Vec2f;
const pi = std.math.pi;
const OBB = @import("../collision.zig").OBB;
const ArrayDeque = @import("../array_deque.zig").ArrayDeque;
const Renderer = platform.Renderer;

pub const Snake = struct {
    alloc: *std.mem.Allocator,
    dead: bool = false,
    target_head_dir: f32 = 0,
    head_segment: Segment,
    segments: std.ArrayList(Segment),
    tail_segment: Segment,

    position_history: ArrayDeque(PastPosition),

    pub fn init(alloc: *std.mem.Allocator) !@This() {
        return Snake{
            .alloc = alloc,
            .head_segment = Segment{
                .pos = Vec2f{ .x = 100, .y = 100 },
                .size = Vec2f{ .x = SNAKE_SEGMENT_LENGTH, .y = SNAKE_HEAD_WIDTH },
                .dir = 0,
            },
            .segments = std.ArrayList(Segment).init(alloc),
            .tail_segment = Segment{
                .pos = Vec2f{ .x = 100, .y = 100 },
                .size = Vec2f{ .x = SNAKE_TAIL_LENGTH, .y = SNAKE_TAIL_WIDTH },
                .dir = 0,
            },
            .position_history = ArrayDeque(PastPosition).init(alloc),
        };
    }

    pub fn update(self: *@This(), current_time: f64, delta: f64) void {
        // Turn head
        const angle_difference = @mod(((self.target_head_dir - self.head_segment.dir) + pi), 2 * pi) - pi;
        const angle_change = std.math.clamp(angle_difference, @floatCast(f32, -SNAKE_TURN_SPEED * delta), @floatCast(f32, SNAKE_TURN_SPEED * delta));
        self.head_segment.dir += angle_change;
        if (self.head_segment.dir >= 2 * pi) {
            self.head_segment.dir -= 2 * pi;
        } else if (self.head_segment.dir < 0) {
            self.head_segment.dir += 2 * pi;
        }

        // Move head
        if (!self.dead) {
            const head_speed = @floatCast(f32, SNAKE_SPEED * delta);
            const head_movement = Vec2f.unitFromRad(self.head_segment.dir).scalMul(head_speed);
            self.head_segment.pos = self.head_segment.pos.add(&head_movement);

            // Wrap head around screen
            if (self.head_segment.pos.x > LEVEL_OFFSET_X + LEVEL_WIDTH / 2.0) {
                self.head_segment.pos.x -= LEVEL_WIDTH;
            }
            if (self.head_segment.pos.x < LEVEL_OFFSET_X - LEVEL_WIDTH / 2.0) {
                self.head_segment.pos.x += LEVEL_WIDTH;
            }
            if (self.head_segment.pos.y > LEVEL_OFFSET_Y + LEVEL_HEIGHT / 2.0) {
                self.head_segment.pos.y -= LEVEL_HEIGHT;
            }
            if (self.head_segment.pos.y < LEVEL_OFFSET_Y - LEVEL_HEIGHT / 2.0) {
                self.head_segment.pos.y += LEVEL_HEIGHT;
            }

            // Track where the head has been
            self.position_history.push(.{ .time = current_time, .pos = self.head_segment.pos, .dir = self.head_segment.dir }) catch builtin.panic("failed to push to position history buffer", null);
        }

        const head_obb = OBB.init(self.head_segment.pos, self.head_segment.size, self.head_segment.dir);

        // Make segments trail head
        var segment_idx: usize = 0;
        var position_history_idx: usize = self.position_history.len() - 1;
        var prev_segment = &self.head_segment;
        while (prev_segment != &self.tail_segment) : (segment_idx += 1) {
            var cur_segment = if (segment_idx < self.segments.len)
                &self.segments.span()[segment_idx]
            else
                &self.tail_segment;

            var time_offset: f64 = undefined;
            if (cur_segment == &self.tail_segment) {
                time_offset = HEAD_TIME_OFFSET + @intToFloat(f64, segment_idx - 1) * SEGMENT_TIME_OFFSET + TAIL_TIME_OFFSET;
            } else {
                time_offset = HEAD_TIME_OFFSET + @intToFloat(f64, segment_idx) * SEGMENT_TIME_OFFSET;
            }

            const segment_time = current_time - time_offset;
            var hist_pos_opt: ?PastPosition = null;
            while (position_history_idx > 0) : (position_history_idx -= 1) {
                if (self.position_history.idx(position_history_idx - 1)) |hist_pos| {
                    if (hist_pos.time < segment_time) {
                        hist_pos_opt = self.position_history.idx(position_history_idx - 1);
                        break;
                    }
                } else {
                    hist_pos_opt = self.position_history.idx(position_history_idx);
                    break;
                }
            }

            if (hist_pos_opt) |hist_pos| {
                if (self.dead and hist_pos.time < segment_time - SEGMENT_TIME_OFFSET / 2) {
                    cur_segment.show = false;
                }
                cur_segment.pos = hist_pos.pos;
                cur_segment.dir = hist_pos.dir;
            }

            // Check if the head collides with this segment
            const cur_obb = OBB.init(cur_segment.pos, cur_segment.size, cur_segment.dir);
            if (!self.dead and segment_idx > 1 and cur_obb.collides(&head_obb)) {
                self.dead = true;
                self.head_segment.show = false;
            }

            prev_segment = cur_segment;
        }

        // Clear the unused history
        var clear_hist_idx: usize = 1;
        while (clear_hist_idx < position_history_idx) : (clear_hist_idx += 1) {
            _ = self.position_history.pop();
        }
    }

    pub fn render(self: @This(), renderer: *Renderer, alpha: f64) void {
        const segments = self.segments.span();
        var idx: usize = segments.len;
        self.tail_segment.render(renderer, SEGMENT_COLORS[(idx + 1) % SEGMENT_COLORS.len]);
        while (idx > 0) : (idx -= 1) {
            const segment = segments[idx - 1];
            segment.render(renderer, SEGMENT_COLORS[idx % SEGMENT_COLORS.len]);
        }
        self.head_segment.render(renderer, SEGMENT_COLORS[0]);
    }

    pub fn addSegment(self: *@This()) void {
        self.segments.append(.{
            .pos = self.tail_segment.pos,
            .dir = self.tail_segment.dir,
            .size = .{ .x = SNAKE_SEGMENT_LENGTH, .y = SNAKE_SEGMENT_WIDTH },
        }) catch unreachable;
    }

    pub fn deinit(self: *@This()) void {}
};

pub const Segment = struct {
    pos: Vec2f,
    size: Vec2f,

    /// In radians
    dir: f32,

    show: bool = true,

    pub fn render(self: *const @This(), render_buffer: *Renderer, color: platform.Color) void {
        if (self.show) {
            render_buffer.pushRect(self.pos, self.size, color, self.dir);
        }
    }
};

pub const PastPosition = struct {
    time: f64,
    pos: Vec2f,
    dir: f32,
};
