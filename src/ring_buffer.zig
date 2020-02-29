const std = @import("std");
const assert = std.debug.assert;

const RingBuffer = struct {
    buffer: []f32,
    head: usize,
    tail: usize,

    pub fn init(buffer: []f32) @This() {
        return .{
            .buffer = buffer,
            .head = 0,
            .tail = 0,
        };
    }

    pub fn push(self: *@This(), data: f32) !void {
        var next = self.head + 1;

        if (next >= self.buffer.len) {
            next = 0;
        }

        if (next == self.tail) {
            return error.BufferOverflow;
        }

        self.buffer[self.head] = data;
        self.head = next;
    }

    pub fn pop(self: *@This()) ?f32 {
        if (self.head == self.tail) {
            return null;
        }

        var next = self.tail + 1;
        if (next >= self.buffer.len) {
            next = 0;
        }

        defer self.tail = next;
        return self.buffer[self.tail];
    }
};

test "Ringbuffer simple test" {
    var buf = [_]f32{0} ** 10;
    var ring = RingBuffer.init(buf[0..]);

    try ring.push(1);
    try ring.push(2);
    try ring.push(3);

    assert(ring.pop().? == 1);
    assert(ring.pop().? == 2);
    assert(ring.pop().? == 3);
    assert(ring.pop() == null);
}
