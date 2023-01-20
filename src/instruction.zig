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

    FloatAdd,
    FloatSubtract,
    FloatMultiply,
    FloatDivide,
    FloatModulo,

    // Bitwise operations
    BitwiseAnd,
    BitwiseOr,
    BitwiseXor,
    BitwiseNot,
    ShiftLeft,
    ShiftRight,

    // Logical operations
    LogicalAnd,
    LogicalOr,
    LogicalNot,

    Equal,
    NotEqual,

    Less,
    LessEqual,
    Greater,
    GreaterEqual,

    FloatLess,
    FloatLessEqual,
    FloatGreater,
    FloatGreaterEqual,

    // Branching operations
    Call,
    ConditionalCall,

    // Load/Store operations
    LoadInt64,
    LoadInt32,
    LoadInt16,
    LoadInt8,
    LoadFloat,
    LoadBool,
    StoreInt64,
    StoreInt32,
    StoreInt16,
    StoreInt8,
    StoreFloat,
    StoreBool,

    // Debug
    // TODO: Remove all debug instructions
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

    FloatAdd,
    FloatSubtract,
    FloatMultiply,
    FloatDivide,
    FloatModulo,

    // Bitwise operations
    BitwiseAnd,
    BitwiseOr,
    BitwiseXor,
    BitwiseNot,
    ShiftLeft,
    ShiftRight,

    // Logical operations
    LogicalAnd,
    LogicalOr,
    LogicalNot,

    Equal,
    NotEqual,

    Less,
    LessEqual,
    Greater,
    GreaterEqual,

    FloatLess,
    FloatLessEqual,
    FloatGreater,
    FloatGreaterEqual,

    // Branching operations
    Call,
    ConditionalCall,

    // Load/Store operations
    LoadInt64,
    LoadInt32,
    LoadInt16,
    LoadInt8,
    LoadFloat,
    LoadBool,
    StoreInt64,
    StoreInt32,
    StoreInt16,
    StoreInt8,
    StoreFloat,
    StoreBool,

    // Debug
    // TODO: Remove all debug instructions
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
            .FloatAdd => Instruction.FloatAdd,
            .FloatSubtract => Instruction.FloatSubtract,
            .FloatMultiply => Instruction.FloatMultiply,
            .FloatDivide => Instruction.FloatDivide,
            .FloatModulo => Instruction.FloatModulo,
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
            .FloatLess => Instruction.FloatLess,
            .FloatLessEqual => Instruction.FloatLessEqual,
            .FloatGreater => Instruction.FloatGreater,
            .FloatGreaterEqual => Instruction.FloatGreaterEqual,
            .LogicalAnd => Instruction.LogicalAnd,
            .LogicalOr => Instruction.LogicalOr,
            .LogicalNot => Instruction.LogicalNot,
            .Call => Instruction.Call,
            .ConditionalCall => Instruction.ConditionalCall,
            .LoadInt64 => Instruction.LoadInt64,
            .LoadInt32 => Instruction.LoadInt32,
            .LoadInt16 => Instruction.LoadInt16,
            .LoadInt8 => Instruction.LoadInt8,
            .LoadFloat => Instruction.LoadFloat,
            .LoadBool => Instruction.LoadBool,
            .StoreInt64 => Instruction.StoreInt64,
            .StoreInt32 => Instruction.StoreInt32,
            .StoreInt16 => Instruction.StoreInt16,
            .StoreInt8 => Instruction.StoreInt8,
            .StoreFloat => Instruction.StoreFloat,
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
                    .Pointer => Value{ .Pointer = try reader.readIntBig(u32) },
                    .Int64 => Value{ .Int64 = try reader.readIntBig(u64) },
                    .Int32 => Value{ .Int64 = try reader.readIntBig(u32) },
                    .Int16 => Value{ .Int64 = try reader.readIntBig(u16) },
                    .Int8 => Value{ .Int64 = try reader.readIntBig(u8) },
                    .Float => Value{ .Float = @bitCast(f64, try reader.readBytesNoEof(@sizeOf(f64))) },
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
                    .Pointer => |constant| try writer.writeIntBig(u32, constant),
                    .Int64 => |constant| try writer.writeIntBig(u64, constant),
                    .Int32 => |constant| try writer.writeIntBig(u32, constant),
                    .Int16 => |constant| try writer.writeIntBig(u16, constant),
                    .Int8 => |constant| try writer.writeIntBig(u8, constant),
                    .Float => |constant| _ = try writer.write(&@bitCast([@sizeOf(f64)]u8, constant)),
                    .Bool => |constant| try writer.writeByte(@boolToInt(constant)),
                }
            },
            else => {},
        }
    }

    return byte_list.items;
}
