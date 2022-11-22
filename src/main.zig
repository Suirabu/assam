const std = @import("std");
const Allocator = std.mem.Allocator;

const assam = @import("assam.zig");

pub fn main() !void {
    // Initialize allocators
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        const leaked = gpa.detectLeaks();
        if (leaked) {
            _ = gpa.deinit();
        }
    }
    var arena = std.heap.ArenaAllocator.init(gpa.allocator());
    defer arena.deinit();

    // Collect command line arguments
    var args = try std.process.argsWithAllocator(arena.allocator());
    // Skip executable path
    std.debug.assert(args.skip());
    // Try to get module path
    const module_path = args.next() orelse {
        const stderr = std.io.getStdErr();
        try display_usage(stderr.writer());
        std.log.err("No source path provided", .{});
        return error.MissingSourcePath;
    };

    const module_file = std.fs.cwd().openFile(module_path, .{}) catch |err| {
        std.log.err("Failed to open file '{s}' for reading", .{module_path});
        return err;
    };
    defer module_file.close();

    const module_contents = try module_file.readToEndAlloc(arena.allocator(), std.math.maxInt(u32));
    const module = try assam.BytecodeModule.from_bytes(module_contents, arena.allocator());

    var vm = assam.VirtualMachine.init(arena.allocator());
    defer vm.deinit();

    try vm.execute_code(module.code);

    const snapshot = vm.get_snapshot();
    std.debug.print("VM output: {any}\n", .{snapshot.data_stack});
}

fn display_usage(writer: anytype) !void {
    try writer.print(
        \\avm - Assam vitual machine
        \\
        \\Usage:
        \\    avm <source>
        \\
    , .{});
}
