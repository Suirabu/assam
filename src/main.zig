const std = @import("std");
const fs = std.fs;
const process = std.process;
const assert = std.debug.assert;

const assam = @import("assam.zig");
const BytecodeModule = assam.BytecodeModule;
const VirtualMachine = assam.VirtualMachine;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        const leaked = gpa.deinit();
        if (leaked) {
            _ = gpa.detectLeaks();
        }
    }
    const allocator = gpa.allocator();

    // Get module path
    var args_iter = try process.argsWithAllocator(allocator);
    assert(args_iter.skip()); // Skip executable path
    const module_path = args_iter.next() orelse {
        const stderr = std.io.getStdErr();
        try displayUsage(stderr.writer());
        fatal("Module path not provided", .{});
    };

    // Attempt to read module contents
    const module_file = try fs.cwd().openFile(module_path, .{});
    defer module_file.close();

    const module_contents = try module_file.readToEndAlloc(allocator, std.math.maxInt(u32));
    defer allocator.free(module_contents);

    // Decode bytecode module
    const module = try BytecodeModule.fromBytes(module_contents, allocator);
    defer module.deinit(allocator);

    var vm = VirtualMachine.init(allocator);
    defer vm.deinit();

    for (module.instructions) |instruction| {
        try vm.executeInstruction(instruction);
    }
}

fn displayUsage(writer: anytype) !void {
    try writer.print(
        \\avm - Assam Virtual Machine
        \\
        \\Usage:
        \\    avm <module>
        \\
        \\
    , .{});
}

fn fatal(comptime format: []const u8, args: anytype) noreturn {
    std.log.err(format, args);
    process.exit(1);
}
