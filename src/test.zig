const std = @import("std");
const testing = std.testing;
const mem = std.mem;

const assam = @import("assam.zig");
const VirtualMachine = assam.VirtualMachine;
const VirtualMachineError = assam.VirtualMachineError;
const Instruction = assam.Instruction;
const InstructionTag = assam.InstructionTag;
const Cell = assam.Cell;
const BytecodeModule = assam.BytecodeModule;

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

test "vm equal" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    var vm = VirtualMachine.init(arena.allocator());
    defer vm.deinit();

    try vm.execute_instruction(Instruction{ .Push = 5 });
    try vm.execute_instruction(Instruction{ .Push = 5 });
    try vm.execute_instruction(Instruction.Equal);
    try vm.execute_instruction(Instruction{ .Push = 5 });
    try vm.execute_instruction(Instruction{ .Push = 7 });
    try vm.execute_instruction(Instruction.Equal);
    const snapshot = vm.get_snapshot();
    try testing.expect(mem.eql(Cell, snapshot.data_stack, &[_]Cell{ 1, 0 }));
}

test "vm less" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    var vm = VirtualMachine.init(arena.allocator());
    defer vm.deinit();

    try vm.execute_instruction(Instruction{ .Push = 5 });
    try vm.execute_instruction(Instruction{ .Push = 5 });
    try vm.execute_instruction(Instruction.Less);
    try vm.execute_instruction(Instruction{ .Push = 5 });
    try vm.execute_instruction(Instruction{ .Push = 7 });
    try vm.execute_instruction(Instruction.Less);
    try vm.execute_instruction(Instruction{ .Push = 7 });
    try vm.execute_instruction(Instruction{ .Push = 5 });
    try vm.execute_instruction(Instruction.Less);
    const snapshot = vm.get_snapshot();
    try testing.expect(mem.eql(Cell, snapshot.data_stack, &[_]Cell{ 0, 1, 0 }));
}

test "vm less equal" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    var vm = VirtualMachine.init(arena.allocator());
    defer vm.deinit();

    try vm.execute_instruction(Instruction{ .Push = 5 });
    try vm.execute_instruction(Instruction{ .Push = 5 });
    try vm.execute_instruction(Instruction.LessEqual);
    try vm.execute_instruction(Instruction{ .Push = 5 });
    try vm.execute_instruction(Instruction{ .Push = 7 });
    try vm.execute_instruction(Instruction.LessEqual);
    try vm.execute_instruction(Instruction{ .Push = 7 });
    try vm.execute_instruction(Instruction{ .Push = 5 });
    try vm.execute_instruction(Instruction.LessEqual);
    const snapshot = vm.get_snapshot();
    try testing.expect(mem.eql(Cell, snapshot.data_stack, &[_]Cell{ 1, 1, 0 }));
}

test "vm greater" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    var vm = VirtualMachine.init(arena.allocator());
    defer vm.deinit();

    try vm.execute_instruction(Instruction{ .Push = 5 });
    try vm.execute_instruction(Instruction{ .Push = 5 });
    try vm.execute_instruction(Instruction.Greater);
    try vm.execute_instruction(Instruction{ .Push = 5 });
    try vm.execute_instruction(Instruction{ .Push = 7 });
    try vm.execute_instruction(Instruction.Greater);
    try vm.execute_instruction(Instruction{ .Push = 7 });
    try vm.execute_instruction(Instruction{ .Push = 5 });
    try vm.execute_instruction(Instruction.Greater);
    const snapshot = vm.get_snapshot();
    try testing.expect(mem.eql(Cell, snapshot.data_stack, &[_]Cell{ 0, 0, 1 }));
}

test "vm greater equal" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    var vm = VirtualMachine.init(arena.allocator());
    defer vm.deinit();

    try vm.execute_instruction(Instruction{ .Push = 5 });
    try vm.execute_instruction(Instruction{ .Push = 5 });
    try vm.execute_instruction(Instruction.GreaterEqual);
    try vm.execute_instruction(Instruction{ .Push = 5 });
    try vm.execute_instruction(Instruction{ .Push = 7 });
    try vm.execute_instruction(Instruction.GreaterEqual);
    try vm.execute_instruction(Instruction{ .Push = 7 });
    try vm.execute_instruction(Instruction{ .Push = 5 });
    try vm.execute_instruction(Instruction.GreaterEqual);
    const snapshot = vm.get_snapshot();
    try testing.expect(mem.eql(Cell, snapshot.data_stack, &[_]Cell{ 1, 0, 1 }));
}

test "vm and" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    var vm = VirtualMachine.init(arena.allocator());
    defer vm.deinit();

    try vm.execute_instruction(Instruction{ .Push = 1 });
    try vm.execute_instruction(Instruction{ .Push = 0 });
    try vm.execute_instruction(Instruction.And);
    try vm.execute_instruction(Instruction{ .Push = 1 });
    try vm.execute_instruction(Instruction{ .Push = 1 });
    try vm.execute_instruction(Instruction.And);
    try vm.execute_instruction(Instruction{ .Push = 0 });
    try vm.execute_instruction(Instruction{ .Push = 0 });
    try vm.execute_instruction(Instruction.And);
    const snapshot = vm.get_snapshot();
    try testing.expect(mem.eql(Cell, snapshot.data_stack, &[_]Cell{ 0, 1, 0 }));
}

test "vm or" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    var vm = VirtualMachine.init(arena.allocator());
    defer vm.deinit();

    try vm.execute_instruction(Instruction{ .Push = 1 });
    try vm.execute_instruction(Instruction{ .Push = 0 });
    try vm.execute_instruction(Instruction.Or);
    try vm.execute_instruction(Instruction{ .Push = 1 });
    try vm.execute_instruction(Instruction{ .Push = 1 });
    try vm.execute_instruction(Instruction.Or);
    try vm.execute_instruction(Instruction{ .Push = 0 });
    try vm.execute_instruction(Instruction{ .Push = 0 });
    try vm.execute_instruction(Instruction.Or);
    const snapshot = vm.get_snapshot();
    try testing.expect(mem.eql(Cell, snapshot.data_stack, &[_]Cell{ 1, 1, 0 }));
}

test "vm not" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    var vm = VirtualMachine.init(arena.allocator());
    defer vm.deinit();

    try vm.execute_instruction(Instruction{ .Push = 1 });
    try vm.execute_instruction(Instruction.Not);
    try vm.execute_instruction(Instruction{ .Push = 0 });
    try vm.execute_instruction(Instruction.Not);
    const snapshot = vm.get_snapshot();
    try testing.expect(mem.eql(Cell, snapshot.data_stack, &[_]Cell{ 0, 1 }));
}

test "Bytecode.from_bytes" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();

    const bytes = "ABF" ++ &[_]u8{ 1, 2, 3, 0x11, 0x12, 0x10, 0, 0, 0, 0, 0, 0, 0, 10 };

    const module = try BytecodeModule.from_bytes(bytes, arena.allocator());
    try testing.expect(module.major_version == 1);
    try testing.expect(module.minor_version == 2);
    try testing.expect(module.patch_version == 3);
    try testing.expect(module.instructions[0] == InstructionTag.Pop);
    try testing.expect(module.instructions[1] == InstructionTag.Dup);
    try testing.expect(module.instructions[2] == InstructionTag.Push);
}

test "Bytecode.to_bytes" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();

    var instructions = [_]Instruction{
        Instruction.Pop,
        Instruction.Dup,
        Instruction{ .Push = 10 },
    };

    const module = BytecodeModule{
        .major_version = 1,
        .minor_version = 2,
        .patch_version = 3,
        .instructions = instructions[0..],
    };

    const bytes = try module.to_bytes(arena.allocator());
    const expected = "ABF" ++ &[_]u8{ 1, 2, 3, 0x11, 0x12, 0x10, 0, 0, 0, 0, 0, 0, 0, 10 };
    try testing.expect(mem.eql(u8, bytes, expected));
}
