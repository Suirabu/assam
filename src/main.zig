const std = @import("std");

const vm_mod = @import("vm.zig");
const VirtualMachine = vm_mod.VirtualMachine;
const VirtualMachineError = vm_mod.VirtualMachineError;

const instruction_mod = @import("instruction.zig");
const Instruction = instruction_mod.Instruction;
const InstructionTag = instruction_mod.InstructionTag;

pub fn main() !void {
    // Prints to stderr (it's a shortcut based on `std.io.getStdErr()`)
    std.debug.print("All your {s} are belong to us.\n", .{"codebase"});

    // stdout is for the actual output of your application, for example if you
    // are implementing gzip, then only the compressed bytes should be sent to
    // stdout, not any debugging messages.
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    try stdout.print("Run `zig build test` to run the tests.\n", .{});

    try bw.flush(); // don't forget to flush!
}

test "vm instruction execution" {
    var vm = VirtualMachine.init(std.testing.allocator);
    defer vm.deinit();

    try vm.executeInstruction(Instruction{ .Push = 5 });
    try vm.executeInstruction(Instruction{ .Push = 10 });
    try vm.executeInstruction(Instruction.Drop);
    try std.testing.expect(vm.data_stack.pop() == 5);
    try std.testing.expectError(VirtualMachineError.StackUnderflow, vm.executeInstruction(Instruction.Drop));
}
