const std = @import("std");
const mem = std.mem;
const Allocator = mem.Allocator;

const assam = @import("assam.zig");
const Value = assam.Value;
const ValueTag = assam.ValueTag;

pub const Block = []Instruction;

pub const Instruction = union(InstructionTag) {
    // Stack operations
    push: Value,
    drop,

    // Arithmetic operations
    add,
    subtract,
    multiply,
    divide,
    modulo,

    float_add,
    float_subtract,
    float_multiply,
    float_divide,
    float_modulo,

    // Bitwise operations
    bitwise_and,
    bitwise_or,
    bitwise_xor,
    bitwise_not,
    shift_left,
    shift_right,

    // Logical operations
    logical_and,
    logical_or,
    logical_not,

    equal,
    not_equal,

    less,
    less_equal,
    greater,
    greater_equal,

    float_less,
    float_less_equal,
    float_greater,
    float_greater_equal,

    // Branching operations
    call,
    conditional_call,

    // Load/Store operations
    load_int,
    load_float,
    load_bool,
    store_int,
    store_float,
    store_bool,

    // Debug
    // TODO: Remove all debug instructions
    print,
};

pub const InstructionTag = enum(u8) {
    const Self = @This();

    // Stack operations
    push,
    drop,

    // Arithmetic operations
    add,
    subtract,
    multiply,
    divide,
    modulo,

    float_add,
    float_subtract,
    float_multiply,
    float_divide,
    float_modulo,

    // Bitwise operations
    bitwise_and,
    bitwise_or,
    bitwise_xor,
    bitwise_not,
    shift_left,
    shift_right,

    // Logical operations
    logical_and,
    logical_or,
    logical_not,

    equal,
    not_equal,

    less,
    less_equal,
    greater,
    greater_equal,

    float_less,
    float_less_equal,
    float_greater,
    float_greater_equal,

    // Branching operations
    call,
    conditional_call,

    // Load/Store operations
    load_int,
    load_float,
    load_bool,
    store_int,
    store_float,
    store_bool,

    // Debug
    // TODO: Remove all debug instructions
    print,

    pub fn toInstruction(self: Self) Instruction {
        return switch (self) {
            .push => Instruction{ .push = undefined },
            .drop => Instruction.drop,
            .add => Instruction.add,
            .subtract => Instruction.subtract,
            .multiply => Instruction.multiply,
            .divide => Instruction.divide,
            .modulo => Instruction.modulo,
            .float_add => Instruction.float_add,
            .float_subtract => Instruction.float_subtract,
            .float_multiply => Instruction.float_multiply,
            .float_divide => Instruction.float_divide,
            .float_modulo => Instruction.float_modulo,
            .bitwise_and => Instruction.bitwise_and,
            .bitwise_or => Instruction.bitwise_or,
            .bitwise_xor => Instruction.bitwise_xor,
            .bitwise_not => Instruction.bitwise_not,
            .shift_left => Instruction.shift_left,
            .shift_right => Instruction.shift_right,
            .equal => Instruction.equal,
            .not_equal => Instruction.not_equal,
            .less => Instruction.less,
            .less_equal => Instruction.less_equal,
            .greater => Instruction.greater,
            .greater_equal => Instruction.greater_equal,
            .float_less => Instruction.float_less,
            .float_less_equal => Instruction.float_less_equal,
            .float_greater => Instruction.float_greater,
            .float_greater_equal => Instruction.float_greater_equal,
            .logical_and => Instruction.logical_and,
            .logical_or => Instruction.logical_or,
            .logical_not => Instruction.logical_not,
            .call => Instruction.call,
            .conditional_call => Instruction.conditional_call,
            .load_int => Instruction.load_int,
            .load_float => Instruction.load_float,
            .load_bool => Instruction.load_bool,
            .store_int => Instruction.store_int,
            .store_float => Instruction.store_float,
            .store_bool => Instruction.store_bool,
            .print => Instruction.print,
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
            .push => blk: {
                const value_tag = @intToEnum(ValueTag, try reader.readByte());
                const value = switch (value_tag) {
                    .BlockIndex => Value{ .BlockIndex = try reader.readIntBig(u32) },
                    .Pointer => Value{ .Pointer = try reader.readIntBig(u32) },
                    .Int => Value{ .Int = try reader.readIntBig(u64) },
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
            .push => |value| {
                const value_tag: ValueTag = value;
                try writer.writeByte(@enumToInt(value_tag));
                switch (value) {
                    .BlockIndex => |constant| try writer.writeIntBig(u32, constant),
                    .Pointer => |constant| try writer.writeIntBig(u32, constant),
                    .Int => |constant| try writer.writeIntBig(u64, constant),
                    .Float => |constant| _ = try writer.write(&@bitCast([@sizeOf(f64)]u8, constant)),
                    .Bool => |constant| try writer.writeByte(@boolToInt(constant)),
                }
            },
            else => {},
        }
    }

    return byte_list.items;
}
