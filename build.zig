const std = @import("std");
const Build = std.Build;

pub fn build(b: *std.Build) void {
    const target = b.resolveTargetQuery(.{
        .cpu_arch = .wasm32,
        .os_tag = .freestanding,
    });
    const optimize = b.standardOptimizeOption(.{
        .preferred_optimize_mode = .ReleaseSmall,
    });

    const bindings = b.createModule(.{
        .root_source_file = b.path("src/wasm4.zig"),
    });

    const game = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "wasm4", .module = bindings },
        },
        .strip = true,
    });

    const wasm = b.addExecutable(.{
        .name = "cart",
        .root_module = game,
    });
    wasm.entry = .disabled;
    wasm.root_module.export_symbol_names = &[_][]const u8{ "start", "update" };
    wasm.import_memory = true;
    wasm.initial_memory = 65536;
    wasm.max_memory = 65536;
    // WASM-4 keeps MMIO registers around address 0.
    // The stack grows downward, and WebAssembly pages are 64KB.
    wasm.stack_size = 14752;

    b.installArtifact(wasm);

    const run_cmd = b.addSystemCommand(&.{ "w4", "run-native" });
    run_cmd.addArtifactArg(wasm);

    const run_step = b.step("run", "Launch WASM-4 and run the game");
    run_step.dependOn(&run_cmd.step);

    const watch_cmd = b.addSystemCommand(&.{ "w4", "watch" });
    watch_cmd.addArtifactArg(wasm);

    const watch_step = b.step("watch", "Launch WASM-4 and watch for changes");
    watch_step.dependOn(&watch_cmd.step);
}
