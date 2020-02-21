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
var shader_program: platform.GLuint = undefined;
var vbo: platform.GLuint = undefined;
var ebo: platform.GLuint = undefined;
var projectionMatrixUniformLocation: platform.GLint = undefined;

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

    vbo = platform.glCreateBuffer();
    ebo = platform.glCreateBuffer();
    //vao = platform.glCreateVertexArrays();

    const vShaderSrc =
        \\ #version 300 es
        \\ layout(location = 0) in vec2 a_position;
        \\ layout(location = 1) in vec3 a_color;
        \\ uniform mat4 projectionMatrix;
        \\ out vec3 v_color;
        \\ void main() {
        \\   v_color = a_color;
        \\   gl_Position = vec4(a_position.x, a_position.y, 0.0, 1.0);
        \\   gl_Position *= projectionMatrix;
        \\ }
    ;
    const fShaderSrc =
        \\ #version 300 es
        \\ precision mediump float;
        \\ in vec3 v_color;
        \\ out vec4 o_fragColor;
        \\ void main() {
        \\   o_fragColor = vec4(v_color, 1.0);
        \\ }
    ;

    const vShader = platform.glCreateShader(platform.GL_VERTEX_SHADER);
    platform.setShaderSource(vShader, vShaderSrc);
    platform.glCompileShader(vShader);
    defer platform.glDeleteShader(vShader);

    if (!platform.getShaderCompileStatus(vShader)) {
        var infoLog: [512]u8 = [_]u8{0} ** 512;
        var infoLen: platform.GLsizei = 0;
        platform.glGetShaderInfoLog(vShader, infoLog.len, &infoLen, &infoLog);
        platform.warn("Error compiling vertex shader: {}\n", .{infoLog[0..@intCast(usize, infoLen)]});
    }

    const fShader = platform.glCreateShader(platform.GL_FRAGMENT_SHADER);
    platform.setShaderSource(fShader, fShaderSrc);
    platform.glCompileShader(fShader);
    defer platform.glDeleteShader(fShader);

    if (!platform.getShaderCompileStatus(vShader)) {
        var infoLog: [512]u8 = [_]u8{0} ** 512;
        var infoLen: platform.GLsizei = 0;
        platform.glGetShaderInfoLog(fShader, infoLog.len, &infoLen, &infoLog);
        platform.warn("Error compiling fragment shader: {}\n", .{infoLog[0..@intCast(usize, infoLen)]});
    }

    shader_program = platform.glCreateProgram();
    platform.glAttachShader(shader_program, vShader);
    platform.glAttachShader(shader_program, fShader);
    platform.glLinkProgram(shader_program);

    if (!platform.getProgramLinkStatus(shader_program)) {
        var infoLog: [512]u8 = [_]u8{0} ** 512;
        var infoLen: platform.GLsizei = 0;
        platform.glGetProgramInfoLog(shader_program, infoLog.len, &infoLen, &infoLog);
        platform.warn("Error linking shader program: {}\n", .{infoLog[0..@intCast(usize, infoLen)]});
    }

    platform.glUseProgram(shader_program);
    projectionMatrixUniformLocation = platform.glGetUniformLocation(shader_program, "projectionMatrix");
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

const RenderBuffer = struct {
    const NUM_ATTR = 5;
    verts: [NUM_ATTR * 512]f32 = undefined,
    vertIdx: usize,
    indices: [2 * 3 * 512]platform.GLuint = undefined,
    indIdx: usize,

    fn init() RenderBuffer {
        return .{
            .vertIdx = 0,
            .indIdx = 0,
        };
    }

    fn pushVert(self: *RenderBuffer, x: f32, y: f32, color: platform.Color) usize {
        const idx = self.vertIdx;
        defer self.vertIdx += 1;

        self.verts[idx * NUM_ATTR + 0] = x;
        self.verts[idx * NUM_ATTR + 1] = y;
        self.verts[idx * NUM_ATTR + 2] = @intToFloat(f32, color.r) / 255.0;
        self.verts[idx * NUM_ATTR + 3] = @intToFloat(f32, color.g) / 255.0;
        self.verts[idx * NUM_ATTR + 4] = @intToFloat(f32, color.b) / 255.0;
        return idx;
    }

    fn pushElem(self: *RenderBuffer, vertIdx: usize) void {
        self.indices[self.indIdx] = @intCast(platform.GLuint, vertIdx);
        defer self.indIdx += 1;
    }

    fn pushRect(self: *RenderBuffer, pos: Vec2f, size: Vec2f, color: platform.Color, rot: f32) void {
        const top_left = self.pushVert(pos.x - size.x / 2, pos.y - size.y / 2, color);
        const top_right = self.pushVert(pos.x + size.x / 2, pos.y - size.y / 2, color);
        const bot_left = self.pushVert(pos.x - size.x / 2, pos.y + size.y / 2, color);
        const bot_right = self.pushVert(pos.x + size.x / 2, pos.y + size.y / 2, color);

        self.pushElem(top_left);
        self.pushElem(top_right);
        self.pushElem(bot_right);

        self.pushElem(top_left);
        self.pushElem(bot_right);
        self.pushElem(bot_left);
    }

    fn flush(self: *RenderBuffer) void {
        const screen_size = platform.getScreenSize();
        const projectionMatrix = [_]f32{
            2 / @intToFloat(f32, screen_size.x), 0,                                    0, -1,
            0,                                   -2 / @intToFloat(f32, screen_size.y), 0, 1,
            0,                                   0,                                    1, 0,
            0,                                   0,                                    0, 1,
        };
        platform.glUseProgram(shader_program);

        platform.glBindBuffer(platform.GL_ARRAY_BUFFER, vbo);
        platform.glBufferData(platform.GL_ARRAY_BUFFER, self.verts.len * @sizeOf(f32), &self.verts, platform.GL_STATIC_DRAW);
        platform.glBindBuffer(platform.GL_ELEMENT_ARRAY_BUFFER, ebo);
        platform.glBufferData(platform.GL_ELEMENT_ARRAY_BUFFER, self.indices.len * @sizeOf(platform.GLuint), &self.indices, platform.GL_STATIC_DRAW);

        platform.glUniformMatrix4fv(projectionMatrixUniformLocation, 1, platform.GL_FALSE, &projectionMatrix);

        platform.glEnableVertexAttribArray(0);
        platform.glEnableVertexAttribArray(1);

        platform.glVertexAttribPointer(0, 2, platform.GL_FLOAT, platform.GL_FALSE, 5 * @sizeOf(f32), null);
        platform.glVertexAttribPointer(1, 3, platform.GL_FLOAT, platform.GL_FALSE, 5 * @sizeOf(f32), @intToPtr(*c_void, 2 * @sizeOf(f32)));

        platform.glDrawElements(platform.GL_TRIANGLES, self.indices.len, platform.GL_UNSIGNED_INT, null);
    }
};

pub fn render(alpha: f64) void {
    platform.glClearColor(1, 1, 1, 1);
    platform.glClear(platform.GL_COLOR_BUFFER_BIT);

    var render_buffer = RenderBuffer.init();
    render_buffer.pushRect(head_segment.pos, .{ .x = 50, .y = 50 }, SEGMENT_COLORS[0], 0);
    render_buffer.flush();

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

    platform.renderPresent();
}

fn addSegment() void {
    if (next_segment_idx == segments.len) {
        platform.warn("Ran out of space for snake segments\n", .{});
        return;
    }
    segments[next_segment_idx] = tail_segment;
    next_segment_idx += 1;
}
