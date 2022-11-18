const std = @import("std");
const testing = std.testing;
const assam = @import("assam.zig");

test "vm stack operations" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();

    var vm = assam.VirtualMachine.init(arena.allocator());
    defer vm.deinit();

    try vm.execute_instruction(assam.Instruction{ .Push = 15 });
    try vm.execute_instruction(assam.Instruction{ .Push = 10 });
    try vm.execute_instruction(assam.Instruction.Pop);

    try testing.expect(vm.data_stack.items.len == 1);
}
