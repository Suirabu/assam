const std = @import("std");
const fs = std.fs;
const process = std.process;
const assert = std.debug.assert;

const assam = @import("assam");
const BytecodeModule = assam.BytecodeModule;
const Instruction = assam.Instruction;

const Assembler = @import("asm.zig").Assembler;

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
    const source_path = args_iter.next() orelse {
        const stderr = std.io.getStdErr();
        try displayUsage(stderr.writer());
        fatal("Module path not provided", .{});
    };

    // Attempt to read module contents
    const source_file = try fs.cwd().openFile(source_path, .{});
    defer source_file.close();

    const source_contents = try source_file.readToEndAlloc(allocator, std.math.maxInt(u32));
    defer allocator.free(source_contents);

    // Assemble source contents into bytecode module
    var assembler = Assembler.init(source_contents, allocator);
    defer assembler.deinit();
    var module = try assembler.assembleFromSource();
    defer module.deinit(allocator);

    var bytes = try module.toBytes(allocator);
    defer allocator.free(bytes);

    // Write bytes to file
    var out_path_array_list = std.ArrayList(u8).init(allocator);
    defer out_path_array_list.deinit();
    var out_path_writer = out_path_array_list.writer();
    try out_path_writer.print("{s}.abm", .{fs.path.stem(source_path)});
    const out_path = try out_path_array_list.toOwnedSlice();
    defer allocator.free(out_path);

    var out_file = try fs.cwd().createFile(out_path, .{});
    defer out_file.close();
    _ = try out_file.write(bytes);
}

fn displayUsage(writer: anytype) !void {
    try writer.print(
        \\ast-asm - Assam text assembler
        \\
        \\Usage:
        \\    ast-asm <module>
        \\
        \\
    , .{});
}

fn fatal(comptime format: []const u8, args: anytype) noreturn {
    std.log.err(format, args);
    process.exit(1);
}
