const std = @import("std");
const testing = std.testing;
const mem = std.mem;

const assam = @import("assam.zig");
const VirtualMachine = assam.VirtualMachine;
const VirtualMachineError = assam.VirtualMachineError;
const Instruction = assam.Instruction;
const Cell = assam.Cell;

test "vm push" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    var vm = VirtualMachine.init(arena.allocator());
    defer vm.deinit();

    try testing.expect(vm.data_stack.items.len == 0);
    try vm.execute_instruction(Instruction{ .Push = 15 });
    try testing.expect(vm.data_stack.items.len == 1);
    try vm.execute_instruction(Instruction{ .Push = 10 });
    try testing.expect(vm.data_stack.items.len == 2);
}

test "vm pop" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    var vm = VirtualMachine.init(arena.allocator());
    defer vm.deinit();

    try vm.execute_instruction(Instruction{ .Push = 15 });
    try testing.expect(vm.data_stack.items.len == 1);
    try vm.execute_instruction(Instruction.Pop);
    try testing.expect(vm.data_stack.items.len == 0);
    const result = vm.execute_instruction(Instruction.Pop);
    try testing.expectError(VirtualMachineError.StackUnderflow, result);
}

test "vm dup" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    var vm = VirtualMachine.init(arena.allocator());
    defer vm.deinit();

    try vm.execute_instruction(Instruction{ .Push = 10 });
    try vm.execute_instruction(Instruction.Dup);
    try testing.expect(mem.eql(Cell, vm.data_stack.items, &[_]Cell{ 10, 10 }));
}

test "vm over" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    var vm = VirtualMachine.init(arena.allocator());
    defer vm.deinit();

    try vm.execute_instruction(Instruction{ .Push = 10 });
    try vm.execute_instruction(Instruction{ .Push = 15 });
    try vm.execute_instruction(Instruction.Over);
    try testing.expect(mem.eql(Cell, vm.data_stack.items, &[_]Cell{ 10, 15, 10 }));
}

test "vm swap" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    var vm = VirtualMachine.init(arena.allocator());
    defer vm.deinit();

    try vm.execute_instruction(Instruction{ .Push = 15 });
    try vm.execute_instruction(Instruction{ .Push = 10 });
    try vm.execute_instruction(Instruction.Swap);
    try testing.expect(mem.eql(Cell, vm.data_stack.items, &[_]Cell{ 10, 15 }));
}

test "vm rot" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    var vm = VirtualMachine.init(arena.allocator());
    defer vm.deinit();

    try vm.execute_instruction(Instruction{ .Push = 10 });
    try vm.execute_instruction(Instruction{ .Push = 15 });
    try vm.execute_instruction(Instruction{ .Push = 20 });
    try vm.execute_instruction(Instruction.Rot);
    try testing.expect(mem.eql(Cell, vm.data_stack.items, &[_]Cell{ 20, 10, 15 }));
}
