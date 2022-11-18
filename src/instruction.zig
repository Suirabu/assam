const assam = @import("assam.zig");
const Cell = assam.Cell;

pub const Instruction = union(InstructionTag) {
    Push: Cell,
    Pop,
    Dup,
    Over,
    Swap,
    Rot,
};

pub const InstructionTag = enum {
    Push,
    Pop,
    Dup,
    Over,
    Swap,
    Rot,
};
