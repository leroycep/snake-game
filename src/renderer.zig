const platform = @import("platform.zig");
const Vec2f = platform.Vec2f;
usingnamespace @import("constants.zig");

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

pub const Renderer = struct {
    const NUM_ATTR = 5;
    verts: [NUM_ATTR * 512]f32 = undefined,
    vertIdx: usize,
    indices: [2 * 3 * 512]platform.GLushort = undefined,
    indIdx: usize,
    translation: Vec2f = Vec2f{ .x = 0, .y = 0 },

    shader_program: platform.GLuint,
    vbo: platform.GLuint,
    ebo: platform.GLuint,
    projectionMatrixUniformLocation: platform.GLint,

    pub fn init() Renderer {
        const vbo = platform.glCreateBuffer();
        const ebo = platform.glCreateBuffer();

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

        const shader_program = platform.glCreateProgram();
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
        const projectionMatrixUniformLocation = platform.glGetUniformLocation(shader_program, "projectionMatrix");

        return .{
            .vertIdx = 0,
            .indIdx = 0,
            .shader_program = shader_program,
            .vbo = vbo,
            .ebo = ebo,
            .projectionMatrixUniformLocation = projectionMatrixUniformLocation,
        };
    }

    fn setTranslation(self: *Renderer, vec: Vec2f) void {
        self.translation = vec;
    }

    fn pushVert(self: *Renderer, pos: Vec2f, color: platform.Color) usize {
        const idx = self.vertIdx;
        defer self.vertIdx += 1;

        self.verts[idx * NUM_ATTR + 0] = pos.x;
        self.verts[idx * NUM_ATTR + 1] = pos.y;
        self.verts[idx * NUM_ATTR + 2] = @intToFloat(f32, color.r) / 255.0;
        self.verts[idx * NUM_ATTR + 3] = @intToFloat(f32, color.g) / 255.0;
        self.verts[idx * NUM_ATTR + 4] = @intToFloat(f32, color.b) / 255.0;
        return idx;
    }

    fn pushElem(self: *Renderer, vertIdx: usize) void {
        self.indices[self.indIdx] = @intCast(platform.GLushort, vertIdx);
        defer self.indIdx += 1;
    }

    fn pushRect(self: *Renderer, pos: Vec2f, size: Vec2f, color: platform.Color, rot: f32) void {
        const top_left = (Vec2f{ .x = -size.x / 2, .y = -size.y / 2 }).rotate(rot).add(&pos);
        const top_right = (Vec2f{ .x = size.x / 2, .y = -size.y / 2 }).rotate(rot).add(&pos);
        const bot_left = (Vec2f{ .x = -size.x / 2, .y = size.y / 2 }).rotate(rot).add(&pos);
        const bot_right = (Vec2f{ .x = size.x / 2, .y = size.y / 2 }).rotate(rot).add(&pos);

        const top_left_vert = self.pushVert(top_left, color);
        const top_right_vert = self.pushVert(top_right, color);
        const bot_left_vert = self.pushVert(bot_left, color);
        const bot_right_vert = self.pushVert(bot_right, color);

        self.pushElem(top_left_vert);
        self.pushElem(top_right_vert);
        self.pushElem(bot_right_vert);

        self.pushElem(top_left_vert);
        self.pushElem(bot_right_vert);
        self.pushElem(bot_left_vert);
    }

    pub fn begin(self: *Renderer) void {
        self.vertIdx = 0;
        self.indIdx = 0;

        platform.glClearColor(1, 1, 1, 1);
        platform.glClear(platform.GL_COLOR_BUFFER_BIT);
    }

    fn flush(self: *Renderer) void {
        const screen_size = platform.getScreenSize();
        const translationMatrix = [_]f32{
            1, 0, 0, -self.translation.x,
            0, 1, 0, -self.translation.y,
            0, 0, 1, 0,
            0, 0, 0, 1,
        };
        const scalingMatrix = [_]f32{
            2 / @intToFloat(f32, VIEWPORT_WIDTH), 0,                                      0, -1,
            0,                                    -2 / @intToFloat(f32, VIEWPORT_HEIGHT), 0, 1,
            0,                                    0,                                      1, 0,
            0,                                    0,                                      0, 1,
        };
        const projectionMatrix = scalingMatrix; //mulMat4(&scalingMatrix, &translationMatrix);
        platform.glUseProgram(self.shader_program);

        platform.glBindBuffer(platform.GL_ARRAY_BUFFER, self.vbo);
        platform.glBufferData(platform.GL_ARRAY_BUFFER, @intCast(c_long, self.vertIdx * NUM_ATTR * @sizeOf(f32)), &self.verts, platform.GL_STATIC_DRAW);
        platform.glBindBuffer(platform.GL_ELEMENT_ARRAY_BUFFER, self.ebo);
        platform.glBufferData(platform.GL_ELEMENT_ARRAY_BUFFER, @intCast(c_long, self.indIdx * @sizeOf(platform.GLushort)), &self.indices, platform.GL_STATIC_DRAW);

        platform.glUniformMatrix4fv(self.projectionMatrixUniformLocation, 1, platform.GL_FALSE, &projectionMatrix);

        platform.glEnableVertexAttribArray(0);
        platform.glEnableVertexAttribArray(1);

        platform.glVertexAttribPointer(0, 2, platform.GL_FLOAT, platform.GL_FALSE, 5 * @sizeOf(f32), null);
        platform.glVertexAttribPointer(1, 3, platform.GL_FLOAT, platform.GL_FALSE, 5 * @sizeOf(f32), @intToPtr(*c_void, 2 * @sizeOf(f32)));

        platform.glDrawElements(platform.GL_TRIANGLES, @intCast(u16, self.indIdx), platform.GL_UNSIGNED_SHORT, null);
    }
};
