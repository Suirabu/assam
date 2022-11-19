const assam = @import("assam.zig");
const Cell = assam.Cell;

pub const Instruction = union(InstructionTag) {
    // Stack operations
    Push: Cell,
    Pop,
    Dup,
    Over,
    Swap,
    Rot,

    // Arithmetic operations
    Add,
    Subtract,
    Multiply,
    Divide,
    Modulo,
};

pub const InstructionTag = enum(u8) {
    // Stack operations
    Push = 0x10,
    Pop = 0x11,
    Dup = 0x12,
    Over = 0x13,
    Swap = 0x14,
    Rot = 0x15,

    // Arithmetic operations
    Add = 0x20,
    Subtract = 0x21,
    Multiply = 0x22,
    Divide = 0x23,
    Modulo = 0x24,

    const Self = @This();

    pub fn as_instruction(self: Self) Instruction {
        return switch (self) {
            .Push => Instruction{ .Push = undefined },
            .Pop => Instruction.Pop,
            .Dup => Instruction.Dup,
            .Over => Instruction.Over,
            .Swap => Instruction.Swap,
            .Rot => Instruction.Rot,
            .Add => Instruction.Add,
            .Subtract => Instruction.Subtract,
            .Multiply => Instruction.Multiply,
            .Divide => Instruction.Divide,
            .Modulo => Instruction.Modulo,
        };
    }
};
