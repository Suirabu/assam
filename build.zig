const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const mode = b.standardReleaseOptions();

    const assam = std.build.Pkg{
        .name = "assam",
        .source = std.build.FileSource{
            .path = "lib/assam.zig",
        },
    };

    // Assam virtual machine
    {
        const avm = b.addExecutable("avm", "avm/main.zig");
        avm.setTarget(target);
        avm.setBuildMode(mode);
        avm.addPackage(assam);
        avm.install();

        const run_cmd = avm.run();
        run_cmd.step.dependOn(b.getInstallStep());
        if (b.args) |args| {
            run_cmd.addArgs(args);
        }

        const run_step = b.step("run-avm", "Run the Assam virtual machine");
        run_step.dependOn(&run_cmd.step);
    }
}
