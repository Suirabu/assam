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

pub const InstructionTag = enum {
    // Stack operations
    Push,
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
