const std = @import("std");
const platform = @import("platform.zig");
const Vec2f = platform.Vec2f;

const TOP_LEFT = Vec2f{ .x = -0.5, .y = -0.5 };
const TOP_RIGHT = Vec2f{ .x = 0.5, .y = -0.5 };
const BOT_LEFT = Vec2f{ .x = -0.5, .y = 0.5 };
const BOT_RIGHT = Vec2f{ .x = 0.5, .y = 0.5 };

/// Oriented Bounding Box
pub const OBB = struct {
    top_left: Vec2f,
    top_right: Vec2f,
    bot_left: Vec2f,
    bot_right: Vec2f,

    pub fn init(pos: Vec2f, size: Vec2f, radians: f32) @This() {
        return .{
            .top_left = size.mul(&TOP_LEFT).rotate(radians).add(&pos),
            .top_right = size.mul(&TOP_RIGHT).rotate(radians).add(&pos),
            .bot_left = size.mul(&BOT_LEFT).rotate(radians).add(&pos),
            .bot_right = size.mul(&BOT_RIGHT).rotate(radians).add(&pos),
        };
    }

    fn project(self: *const @This(), axis: *const Vec2f) [4]f32 {
        return .{
            self.top_left.dot(axis),
            self.top_right.dot(axis),
            self.bot_left.dot(axis),
            self.bot_right.dot(axis),
        };
    }

    pub fn collides(self: *const OBB, other: *const OBB) bool {
        const normals = [_]Vec2f{
            self.top_right.sub(&self.top_left).normalize(),
            self.top_right.sub(&self.bot_right).normalize(),
            other.top_right.sub(&other.top_left).normalize(),
            other.top_right.sub(&other.bot_right).normalize(),
        };

        for (normals) |normal| {
            const a_proj = min_max_pos(self.project(&normal));
            const b_proj = min_max_pos(other.project(&normal));

            // If there is some separation
            if (b_proj.max < a_proj.min or b_proj.min > a_proj.max) {
                // The two boxes are not colliding
                return false;
            }
        }

        return true;
    }
};

const MinMax = struct {
    min: f32,
    max: f32,
};

fn min_max_pos(slice: [4]f32) MinMax {
    var min_max = MinMax{ .min = slice[0], .max = slice[1] };
    for (slice[1..]) |number| {
        if (number > min_max.max) {
            min_max.max = number;
        }
        if (number < min_max.min) {
            min_max.min = number;
        }
    }
    return min_max;
}
