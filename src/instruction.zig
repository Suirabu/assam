pub const Instruction = union(InstructionTag) {
    Push: u64,
    Drop,
};

pub const InstructionTag = enum {
    Push,
    Drop,
};
