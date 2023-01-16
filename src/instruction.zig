const std = @import("std");
const mem = std.mem;
const Allocator = mem.Allocator;

const assam = @import("assam.zig");
const Value = assam.Value;
const ValueTag = assam.ValueTag;

pub const Block = []Instruction;

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

    Call,
    ConditionalCall,

    LoadInt,
    LoadBool,
    StoreInt,
    StoreBool,

    Print,
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

    Call,
    ConditionalCall,

    LoadInt,
    LoadBool,
    StoreInt,
    StoreBool,

    Print,

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
            .Call => Instruction.Call,
            .ConditionalCall => Instruction.ConditionalCall,
            .LoadInt => Instruction.LoadInt,
            .LoadBool => Instruction.LoadBool,
            .StoreInt => Instruction.StoreInt,
            .StoreBool => Instruction.StoreBool,
            .Print => Instruction.Print,
        };
    }
};

pub fn instructionsFromBytes(bytes: []const u8, allocator: Allocator) ![]Instruction {
    var fbs = std.io.fixedBufferStream(bytes);
    var reader = fbs.reader();

    var instructions = std.ArrayList(Instruction).init(allocator);

    while (true) {
        const tag = @intToEnum(InstructionTag, reader.readByte() catch break);
        const instruction = switch (tag) {
            .Push => blk: {
                const value_tag = @intToEnum(ValueTag, try reader.readByte());
                const value = switch (value_tag) {
                    .BlockIndex => Value{ .BlockIndex = try reader.readIntBig(u32) },
                    .Int => Value{ .Int = try reader.readIntBig(u64) },
                    .Bool => Value{ .Bool = try reader.readByte() != 0 },
                };
                break :blk Instruction{ .Push = value };
            },
            else => tag.toInstruction(),
        };
        try instructions.append(instruction);
    }

    return instructions.items;
}

pub fn instructionsToBytes(instructions: []Instruction, allocator: Allocator) ![]u8 {
    var byte_list = std.ArrayList(u8).init(allocator);
    var writer = byte_list.writer();

    for (instructions) |instruction| {
        const tag: InstructionTag = instruction;
        try writer.writeByte(@enumToInt(tag));

        switch (instruction) {
            .Push => |value| {
                const value_tag: ValueTag = value;
                try writer.writeByte(@enumToInt(value_tag));
                switch (value) {
                    .BlockIndex => |constant| try writer.writeIntBig(u32, constant),
                    .Int => |constant| try writer.writeIntBig(u64, constant),
                    .Bool => |constant| try writer.writeByte(@boolToInt(constant)),
                }
            },
            else => {},
        }
    }

    return byte_list.items;
}
