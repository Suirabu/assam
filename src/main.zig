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
    vm.loadBytecodeModule(module);
    defer vm.deinit();

    for (module.blocks[module.start_block_index]) |instruction| {
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

test {
    var builder = assam.ModuleBuilder.init(std.testing.allocator);
    defer builder.deinit();

    var add_block = assam.BlockBuilder.init(&builder);
    var add_block_instructions = [_]assam.Instruction{
        assam.Instruction{ .Push = assam.Value{ .Int = 10 } },
        assam.Instruction{ .Push = assam.Value{ .Int = 5 } },
        assam.Instruction.Add,
    };
    try add_block.appendInstructions(add_block_instructions[0..]);
    try builder.addBlock(add_block);

    var start_block = assam.BlockBuilder.init(&builder);
    var start_instructions = [_]assam.Instruction{
        assam.Instruction{ .Push = assam.Value{ .Int = add_block.index } },
        assam.Instruction.Call,
        assam.Instruction.Drop,
    };
    try start_block.appendInstructions(start_instructions[0..]);
    try builder.addBlock(start_block);
    builder.setStartBlock(start_block);

    var module = try builder.toBytecodeModule();
    defer module.deinit(std.testing.allocator);
    const bytes = try module.toBytes(std.testing.allocator);
    defer std.testing.allocator.free(bytes);
    std.debug.print("\nModule bytes:\n\t{any}\n", .{bytes});
}
