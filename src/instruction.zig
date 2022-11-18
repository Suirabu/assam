const assam = @import("assam.zig");
const Cell = assam.Cell;

pub const Instruction = union(InstructionTag) {
    Push: Cell,
    Pop,
};

pub const InstructionTag = enum {
    Push,
    Pop,
};
