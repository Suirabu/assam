const assam = @import("assam.zig");
const Cell = assam.Cell;

pub const Instruction = union(InstructionTag) {
    // Meta operations
    Halt,

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

    // Logical operations
    Equal,
    Less,
    LessEqual,
    Greater,
    GreaterEqual,
    And,
    Or,
    Not,
};

pub const InstructionTag = enum(u8) {
    // Meta operations
    Halt = 0x01,

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

    // Logical operations
    Equal = 0x30,
    Less = 0x31,
    LessEqual = 0x32,
    Greater = 0x33,
    GreaterEqual = 0x34,
    And = 0x35,
    Or = 0x36,
    Not = 0x37,

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
            .Equal => Instruction.Equal,
            .Less => Instruction.Less,
            .LessEqual => Instruction.LessEqual,
            .Greater => Instruction.Greater,
            .GreaterEqual => Instruction.GreaterEqual,
            .And => Instruction.And,
            .Or => Instruction.Or,
            .Not => Instruction.Not,
        };
    }
};
