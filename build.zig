const build_mod = @import("std").build;
const Builder = build_mod.Builder;

pub fn build(b: *Builder) void {
    const target = b.standardTargetOptions(.{});

    const mode = b.standardReleaseOptions();

    const exe = b.addExecutable("blurhash-zig", "./main.zig");
    exe.setTarget(target);
    exe.setBuildMode(mode);
    exe.addPackagePath("zigimg", "zigimg/zigimg.zig");
    exe.addPackagePath("zig-string", "zig-string/zig-string.zig");
    exe.install();

    const test_step = b.step("test", "Run library tests");
    {
        const test_suite = b.addTest("./main.zig");
        test_suite.addPackagePath("zigimg", "zigimg/zigimg.zig");
        test_suite.addPackagePath("zig-string", "zig-string/zig-string.zig");
        test_suite.step.dependOn(&exe.step);

        test_step.dependOn(&test_suite.step);
    }

    const run_cmd = exe.run();
    if (b.args) |args| { run_cmd.addArgs(args); }
    run_cmd.step.dependOn(b.getInstallStep());

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
