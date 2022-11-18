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

    try testing.expect(vm.get_snapshot().data_stack.len == 0);
    try vm.execute_instruction(Instruction{ .Push = 15 });
    try testing.expect(vm.get_snapshot().data_stack.len == 1);
    try vm.execute_instruction(Instruction{ .Push = 10 });
    try testing.expect(vm.get_snapshot().data_stack.len == 2);
}

test "vm pop" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    var vm = VirtualMachine.init(arena.allocator());
    defer vm.deinit();

    try vm.execute_instruction(Instruction{ .Push = 15 });
    try testing.expect(vm.get_snapshot().data_stack.len == 1);
    try vm.execute_instruction(Instruction.Pop);
    try testing.expect(vm.get_snapshot().data_stack.len == 0);
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
    const snapshot = vm.get_snapshot();
    try testing.expect(mem.eql(Cell, snapshot.data_stack, &[_]Cell{ 10, 10 }));
}

test "vm over" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    var vm = VirtualMachine.init(arena.allocator());
    defer vm.deinit();

    try vm.execute_instruction(Instruction{ .Push = 10 });
    try vm.execute_instruction(Instruction{ .Push = 15 });
    try vm.execute_instruction(Instruction.Over);
    const snapshot = vm.get_snapshot();
    try testing.expect(mem.eql(Cell, snapshot.data_stack, &[_]Cell{ 10, 15, 10 }));
}

test "vm swap" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    var vm = VirtualMachine.init(arena.allocator());
    defer vm.deinit();

    try vm.execute_instruction(Instruction{ .Push = 15 });
    try vm.execute_instruction(Instruction{ .Push = 10 });
    try vm.execute_instruction(Instruction.Swap);
    const snapshot = vm.get_snapshot();
    try testing.expect(mem.eql(Cell, snapshot.data_stack, &[_]Cell{ 10, 15 }));
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
    const snapshot = vm.get_snapshot();
    try testing.expect(mem.eql(Cell, snapshot.data_stack, &[_]Cell{ 20, 10, 15 }));
}

test "vm add" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    var vm = VirtualMachine.init(arena.allocator());
    defer vm.deinit();

    try vm.execute_instruction(Instruction{ .Push = 13 });
    try vm.execute_instruction(Instruction{ .Push = 7 });
    try vm.execute_instruction(Instruction.Add);
    const snapshot = vm.get_snapshot();
    try testing.expect(mem.eql(Cell, snapshot.data_stack, &[_]Cell{20}));
}

test "vm subtract" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    var vm = VirtualMachine.init(arena.allocator());
    defer vm.deinit();

    try vm.execute_instruction(Instruction{ .Push = 13 });
    try vm.execute_instruction(Instruction{ .Push = 7 });
    try vm.execute_instruction(Instruction.Subtract);
    const snapshot = vm.get_snapshot();
    try testing.expect(mem.eql(Cell, snapshot.data_stack, &[_]Cell{6}));
}

test "vm multiply" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    var vm = VirtualMachine.init(arena.allocator());
    defer vm.deinit();

    try vm.execute_instruction(Instruction{ .Push = 13 });
    try vm.execute_instruction(Instruction{ .Push = 7 });
    try vm.execute_instruction(Instruction.Multiply);
    const snapshot = vm.get_snapshot();
    try testing.expect(mem.eql(Cell, snapshot.data_stack, &[_]Cell{91}));
}

test "vm divide" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    var vm = VirtualMachine.init(arena.allocator());
    defer vm.deinit();

    try vm.execute_instruction(Instruction{ .Push = 13 });
    try vm.execute_instruction(Instruction{ .Push = 7 });
    try vm.execute_instruction(Instruction.Divide);
    const snapshot = vm.get_snapshot();
    try testing.expect(mem.eql(Cell, snapshot.data_stack, &[_]Cell{1}));
}

test "vm modulo" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    var vm = VirtualMachine.init(arena.allocator());
    defer vm.deinit();

    try vm.execute_instruction(Instruction{ .Push = 13 });
    try vm.execute_instruction(Instruction{ .Push = 7 });
    try vm.execute_instruction(Instruction.Modulo);
    const snapshot = vm.get_snapshot();
    try testing.expect(mem.eql(Cell, snapshot.data_stack, &[_]Cell{6}));
}
