export default function getWebGLEnv(canvas_element, getMemory) {
    const readCharStr = (ptr, len) => {
        const bytes = new Uint8Array(getMemory().buffer, ptr, len);
        let s = "";
        for (let i = 0; i < len; ++i) {
            s += String.fromCharCode(bytes[i]);
        }
        return s;
    };
    const writeCharStr = (ptr, len, lenRetPtr, text) => {
        const encoder = new TextEncoder();
        const message = encoder.encode(text);
        const zigbytes = new Uint8Array(getMemory().buffer, ptr, len);
        let zigidx = 0;
        for (const b of message) {
            if (zigidx >= len-1) break;
            zigbytes[zigidx] = b;
            zigidx += 1;
        }
        zigbytes[zigidx] = 0;
        if (lenRetPtr !== 0) {
            new Uint32Array(getMemory().buffer, lenRetPtr, 1)[0] = zigidx;
        }
    }

    const gl = canvas_element.getContext('webgl2', {
        antialias: false,
        preserveDrawingBuffer: true,
    });

    if (!gl) {
        throw new Error('The browser does not support WebGL');
    }

    const glShaders = [];
    const glPrograms = [];
    const glBuffers = [];
    const glTextures = [];
    const glFramebuffers = [];
    const glUniformLocations = [];

    return {
        getScreenW() {
            return gl.drawingBufferWidth;
        },
        getScreenH() {
            return gl.drawingBufferHeight;
        },
        glActiveTexture(target) {
            gl.activeTexture(target);
        },
        glAttachShader(program, shader) {
            gl.attachShader(glPrograms[program], glShaders[shader]);
        },
        glBindBuffer(type, buffer_id) {
            gl.bindBuffer(type, glBuffers[buffer_id]);
        },
        glBindFramebuffer(target, framebuffer) {
            gl.bindFramebuffer(target, glFramebuffers[framebuffer]);
        },
        glBindTexture(target, texture_id) {
            gl.bindTexture(target, glTextures[texture_id]);
        },
        glBlendFunc(x, y) {
            gl.blendFunc(x, y);
        },
        glBufferData(type, count, data_ptr, draw_type) {
            const bytes = new Uint8Array(getMemory().buffer, data_ptr, count);
            gl.bufferData(type, bytes, draw_type);
        },
        glCheckFramebufferStatus(target) {
            return gl.checkFramebufferStatus(target);
        },
        glClear(mask) {
            gl.clear(mask);
        },
        glClearColor(r, g, b, a) {
            gl.clearColor(r, g, b, a);
        },
        glCompileShader(shader) {
            gl.compileShader(glShaders[shader]);
        },
        getShaderCompileStatus(shader) {
            return gl.getShaderParameter(glShaders[shader], gl.COMPILE_STATUS);
        },
        glCreateBuffer() {
            glBuffers.push(gl.createBuffer());
            return glBuffers.length - 1;
        },
        glCreateFramebuffer() {
            glFramebuffers.push(gl.createFramebuffer());
            return glFramebuffers.length - 1;
        },
        glCreateProgram() {
            glPrograms.push(gl.createProgram());
            return glPrograms.length - 1;
        },
        glCreateShader(shader_type) {
            glShaders.push(gl.createShader(shader_type));
            return glShaders.length - 1;
        },
        glCreateTexture() {
            glTextures.push(gl.createTexture());
            return glTextures.length - 1;
        },
        glDeleteBuffer(id) {
            gl.deleteBuffer(glBuffers[id]);
            glBuffers[id] = undefined;
        },
        glDeleteProgram(id) {
            gl.deleteProgram(glPrograms[id]);
            glPrograms[id] = undefined;
        },
        glDeleteShader(id) {
            gl.deleteShader(glShaders[id]);
            glShaders[id] = undefined;
        },
        glDeleteTexture(id) {
            gl.deleteTexture(glTextures[id]);
            glTextures[id] = undefined;
        },
        glDepthFunc(x) {
            gl.depthFunc(x);
        },
        glDetachShader(program, shader) {
            gl.detachShader(glPrograms[program], glShaders[shader]);
        },
        glDisable(cap) {
            gl.disable(cap);
        },
        glDrawArrays(type, offset, count) {
            gl.drawArrays(type, offset, count);
        },
        glDrawElements(mode, count, type, offset) {
            gl.drawElements(mode, count, type, offset);
        },
        glEnable(x) {
            gl.enable(x);
        },
        glEnableVertexAttribArray(x) {
            gl.enableVertexAttribArray(x);
        },
        glFramebufferTexture2D(target, attachment, textarget, texture, level) {
            gl.framebufferTexture2D(target, attachment, textarget, glTextures[texture], level);
        },
        glFrontFace(mode) {
            gl.frontFace(mode);
        },
        glGetAttribLocation_(program_id, name_ptr, name_len) {
            const name = readCharStr(name_ptr, name_len);
            return gl.getAttribLocation(glPrograms[program_id], name);
        },
        glGetError() {
            return gl.getError();
        },
        glGetShaderInfoLog(shader, maxLength, length, infoLog) {
            writeCharStr(infoLog, maxLength, length, gl.getShaderInfoLog(glShaders[shader]));
        },
        glGetUniformLocation_(program_id, name_ptr, name_len) {
            const name = readCharStr(name_ptr, name_len);
            glUniformLocations.push(gl.getUniformLocation(glPrograms[program_id], name));
            return glUniformLocations.length - 1;
        },
        glLinkProgram(program) {
            gl.linkProgram(glPrograms[program]);
        },
        getProgramLinkStatus(program) {
            return gl.getProgramParameter(glPrograms[program], gl.LINK_STATUS);
        },
        glGetProgramInfoLog(program, maxLength, length, infoLog) {
            writeCharStr(infoLog, maxLength, length, gl.getProgramInfoLog(glPrograms[program]));
        },
        glPixelStorei(pname, param) {
            gl.pixelStorei(pname, param);
        },
        glShaderSource_(shader, string_ptr, string_len) {
            const string = readCharStr(string_ptr, string_len);
            gl.shaderSource(glShaders[shader], string);
        },
        glTexImage2D(target, level, internal_format, width, height, border, format, type, data_ptr, data_len) {
            // FIXME - look at data_ptr, not data_len, to determine NULL?
            const data = data_len > 0 ? new Uint8Array(getMemory().buffer, data_ptr, data_len) : null;
            gl.texImage2D(target, level, internal_format, width, height, border, format, type, data);
        },
        glTexParameterf(target, pname, param) {
            gl.texParameterf(target, pname, param);
        },
        glTexParameteri(target, pname, param) {
            gl.texParameteri(target, pname, param);
        },
        glUniform1f(location_id, x) {
            gl.uniform1f(glUniformLocations[location_id], x);
        },
        glUniform1i(location_id, x) {
            gl.uniform1i(glUniformLocations[location_id], x);
        },
        glUniform4f(location_id, x, y, z, w) {
            gl.uniform4f(glUniformLocations[location_id], x, y, z, w);
        },
        glUniformMatrix4fv(location_id, data_len, transpose, data_ptr) {
            const floats = new Float32Array(getMemory().buffer, data_ptr, data_len * 16);
            gl.uniformMatrix4fv(glUniformLocations[location_id], transpose, floats);
        },
        glUseProgram(program_id) {
            gl.useProgram(glPrograms[program_id]);
        },
        glVertexAttribPointer(attrib_location, size, type, normalize, stride, offset) {
            gl.vertexAttribPointer(attrib_location, size, type, normalize, stride, offset);
        },
        glViewport(x, y, width, height) {
            gl.viewport(x, y, width, height);
        },
    };
}
