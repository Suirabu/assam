const std = @import("std");
const mem = std.mem;
const Allocator = mem.Allocator;

const Value = @import("assam.zig").Value;

pub const Instruction = union(InstructionTag) {
    // Stack operations
    Push: Value,
    Drop,

    // Arithmetic operations
    Add,
    Subtract,
    Multiply,
    Divide,
    Modulo,

    // Bitwise operations
    BitwiseAnd,
    BitwiseOr,
    BitwiseXor,
    BitwiseNot,
    ShiftLeft,
    ShiftRight,

    // Logical operations
    Equal,
    NotEqual,
    Less,
    LessEqual,
    Greater,
    GreaterEqual,
    LogicalAnd,
    LogicalOr,
    LogicalNot,
};

pub const InstructionTag = enum(u8) {
    const Self = @This();

    // Stack operations
    Push,
    Drop,

    // Arithmetic operations
    Add,
    Subtract,
    Multiply,
    Divide,
    Modulo,

    // Bitwise operations
    BitwiseAnd,
    BitwiseOr,
    BitwiseXor,
    BitwiseNot,
    ShiftLeft,
    ShiftRight,

    // Logical operations
    Equal,
    NotEqual,
    Less,
    LessEqual,
    Greater,
    GreaterEqual,
    LogicalAnd,
    LogicalOr,
    LogicalNot,

    pub fn toInstruction(self: Self) Instruction {
        return switch (self) {
            .Push => Instruction{ .Push = undefined },
            .Drop => Instruction.Drop,
            .Add => Instruction.Add,
            .Subtract => Instruction.Subtract,
            .Multiply => Instruction.Multiply,
            .Divide => Instruction.Divide,
            .Modulo => Instruction.Modulo,
            .BitwiseAnd => Instruction.BitwiseAnd,
            .BitwiseOr => Instruction.BitwiseOr,
            .BitwiseXor => Instruction.BitwiseXor,
            .BitwiseNot => Instruction.BitwiseNot,
            .ShiftLeft => Instruction.ShiftLeft,
            .ShiftRight => Instruction.ShiftRight,
            .Equal => Instruction.Equal,
            .NotEqual => Instruction.NotEqual,
            .Less => Instruction.Less,
            .LessEqual => Instruction.LessEqual,
            .Greater => Instruction.Greater,
            .GreaterEqual => Instruction.GreaterEqual,
            .LogicalAnd => Instruction.LogicalAnd,
            .LogicalOr => Instruction.LogicalOr,
            .LogicalNot => Instruction.LogicalNot,
        };
    }
};
