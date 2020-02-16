const std = @import("std");
const Builder = std.build.Builder;
const sep_str = std.fs.path.sep_str;

const SITE_DIR = "www";

pub fn build(b: *Builder) void {
    const wasm = b.addStaticLibrary("snake-game", "src/main_web.zig");
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
}
