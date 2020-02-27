const std = @import("std");
const platform = @import("platform.zig");
const Vec2f = platform.Vec2f;

pub const Manifold = struct {
    rigidBodyA: *RigidCircle,
    rigidBodyB: *RigidCircle,
    penetration: f32,
    normal: Vec2f,

    pub fn resolve_collision(self: *const @This()) void {
        if (self.rigidBodyA.inv_mass + self.rigidBodyB.inv_mass == 0) {
            return;
        }

        // Calculate relative vel
        const rv = self.rigidBodyB.vel.sub(&self.rigidBodyA.vel);

        const velAlongNormal = rv.dot(&self.normal);

        // If the two objects are separating, don't do anything
        if (velAlongNormal > 0) {
            return;
        }

        const restitution = std.math.min(self.rigidBodyA.restitution, self.rigidBodyB.restitution);

        const j = -(1 + restitution) * velAlongNormal;
        const impulseScalar = j / (self.rigidBodyA.inv_mass + self.rigidBodyB.inv_mass);

        const impulse = self.normal.scalMul(impulseScalar);
        self.rigidBodyA.vel = self.rigidBodyA.vel.sub(&impulse.scalMul(self.rigidBodyA.inv_mass));
        self.rigidBodyB.vel = self.rigidBodyB.vel.add(&impulse.scalMul(self.rigidBodyB.inv_mass));
    }

    // Prevent objects from sinking into each other
    pub fn position_correction(self: *const @This()) void {
        const percent = 0.2;
        const slop = 0.01;
        const correction_amount = (std.math.max(self.penetration - slop, 0) / (self.rigidBodyA.inv_mass + self.rigidBodyB.inv_mass)) * percent;
        const correction = self.normal.scalMul(correction_amount);
        self.rigidBodyA.pos = self.rigidBodyA.pos.sub(&correction.scalMul(self.rigidBodyA.inv_mass));
        self.rigidBodyB.pos = self.rigidBodyB.pos.add(&correction.scalMul(self.rigidBodyB.inv_mass));
    }
};

pub const RigidCircle = struct {
    radius: f32,
    pos: Vec2f,
    vel: Vec2f,
    restitution: f32,
    inv_mass: f32,

    pub fn overlaps(self: *const @This(), other: *const @This()) void {
        const r = self.radius + other.radius;
        const r2 = r * r;
        const x_dist = self.pos.x + other.pos.x;
        const y_dist = self.pos.y + other.pos.y;
        return r2 < x_dist * x_dist + y_dist * y_dist;
    }

    pub fn collsion(self: *@This(), other: *@This()) ?Manifold {
        const n = other.pos.sub(&self.pos);

        const r = self.radius + other.radius;
        const r2 = r * r;

        if (n.magnitudeSquared() > r2) {
            return null;
        }

        const distance = n.magnitude();
        if (distance != 0) {
            return Manifold{
                .rigidBodyA = self,
                .rigidBodyB = other,
                .penetration = r - distance,
                .normal = n.scalDiv(distance),
            };
        } else {
            return Manifold{
                .rigidBodyA = self,
                .rigidBodyB = other,
                .penetration = self.radius,
                .normal = .{ .x = 1, .y = 0 },
            };
        }
    }
};
