pub const Instruction = union(InstructionTag) {
    // Stack operations
    Push: u64,
    Drop,

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
    Drop,

    // Arithmetic operations
    Add,
    Subtract,
    Multiply,
    Divide,
    Modulo,
};