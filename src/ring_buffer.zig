const std = @import("std");
const assert = std.debug.assert;

pub fn RingBuffer(comptime T: type) type {
    return struct {
        buffer: []T,
        head: usize,
        tail: usize,

        pub fn init(buffer: []T) @This() {
            return .{
                .buffer = buffer,
                .head = 0,
                .tail = 0,
            };
        }

        pub fn push(self: *@This(), data: T) !void {
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

        pub fn pop(self: *@This()) ?T {
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

        pub fn len(self: *@This()) usize {
            if (self.head == self.tail) {
                return 0;
            } else if (self.head > self.tail) {
                return self.head - self.tail;
            } else {
                return self.buffer.len - self.tail + self.head;
            }
        }

        pub fn capacity(self: *@This()) usize {
            return self.buffer.len - 1;
        }
    };
}

test "Ringbuffer simple test" {
    var buf = [_]i32{0} ** 10;
    var ring = RingBuffer(i32).init(buf[0..]);

    try ring.push(1);
    try ring.push(2);
    try ring.push(3);

    assert(ring.head == 3);

    assert(ring.pop().? == 1);
    assert(ring.pop().? == 2);
    assert(ring.pop().? == 3);
    assert(ring.pop() == null);
}
