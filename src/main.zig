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

    var vm = try VirtualMachine.init(module, allocator);
    defer vm.deinit();

    try vm.run();
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

    var result_addr = builder.allocateGlobalInt(u16);

    var add_block = assam.BlockBuilder.init(&builder);
    var add_block_instructions = [_]assam.Instruction{
        assam.Instruction{ .Push = assam.Value{ .Pointer = result_addr } },
        assam.Instruction{ .Push = assam.Value{ .Int8 = 0x01 } },
        assam.Instruction.StoreInt8,
        assam.Instruction{ .Push = assam.Value{ .Pointer = result_addr } },
        assam.Instruction{ .Push = assam.Value{ .Int8 = 1 } },
        assam.Instruction.Add,
        assam.Instruction{ .Push = assam.Value{ .Int8 = 0x01 } },
        assam.Instruction.StoreInt8,
    };
    try add_block.appendInstructions(add_block_instructions[0..]);
    try builder.addBlock(add_block);

    var start_block = assam.BlockBuilder.init(&builder);
    var start_instructions = [_]assam.Instruction{
        assam.Instruction{ .Push = assam.Value{ .BlockIndex = add_block.index } },
        assam.Instruction.Call,
        assam.Instruction{ .Push = assam.Value{ .Pointer = result_addr } },
        assam.Instruction.LoadInt16,
        assam.Instruction.Print,
    };
    try start_block.appendInstructions(start_instructions[0..]);
    try builder.addBlock(start_block);
    builder.setStartBlock(start_block);

    var module = try builder.toBytecodeModule();
    defer module.deinit(std.testing.allocator);

    var vm = try assam.VirtualMachine.init(module, std.testing.allocator);
    defer vm.deinit();

    try vm.run();
}
