const std = @import("std");
const Builder = std.build.Builder;
const sep_str = std.fs.path.sep_str;

const SITE_DIR = "www";

pub fn build(b: *Builder) void {
    const target = b.standardTargetOptions(null);
    const exe = b.addExecutable("snake-game", "src/main_native.zig");
    exe.setBuildMode(b.standardReleaseOptions());
    exe.setTheTarget(target);
    exe.linkSystemLibrary("SDL2");
    exe.addIncludeDir("./c/include/");
    exe.addCSourceFile("./c/src/glad.c", &[_][]const u8{});
    exe.linkLibC();
    exe.install();

    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());

    const wasm = b.addStaticLibrary("snake-game", "src/main_web.zig");
    wasm.step.dependOn(&b.addExecutable("webgl_generate", "tools/webgl_generate.zig").run().step);
    const wasmOutDir = b.fmt("{}" ++ sep_str ++ SITE_DIR, .{b.install_prefix});
    wasm.setOutputDir(wasmOutDir);
    wasm.setBuildMode(b.standardReleaseOptions());
    wasm.setTarget(.wasm32, .freestanding, .none);

    const htmlInstall = b.addInstallFile("./index.html", SITE_DIR ++ sep_str ++ "index.html");
    const cssInstall = b.addInstallFile("./index.css", SITE_DIR ++ sep_str ++ "index.css");
    const jsInstall = b.addInstallDirectory(.{
        .source_dir = "js",
        .install_dir = .Prefix,
        .install_subdir = SITE_DIR ++ sep_str ++ "js",
    });

    wasm.step.dependOn(&htmlInstall.step);
    wasm.step.dependOn(&cssInstall.step);
    wasm.step.dependOn(&jsInstall.step);

    b.step("wasm", "Build WASM binary").dependOn(&wasm.step);
    b.step("native", "Build the native binary").dependOn(&exe.step);
    b.step("run", "Run the native binary").dependOn(&run_cmd.step);

    const all = b.step("all", "Build all binaries");
    all.dependOn(&wasm.step);
    all.dependOn(&exe.step);
}
