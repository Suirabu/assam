const std = @import("std");
const mem = std.mem;
const Allocator = mem.Allocator;

const assam = @import("assam.zig");
const Value = assam.Value;
const ValueTag = assam.ValueTag;

pub const Block = []Instruction;

pub const Instruction = union(InstructionTag) {
    // Int instructions
    int_push: u64,

    int_add,
    int_subtract,
    int_multiply,
    int_divide,
    int_modulo,

    int_and,
    int_or,
    int_xor,
    int_not,
    int_shift_left,
    int_shift_right,

    int_equal,
    int_not_equal,

    int_less,
    int_less_equal,
    int_greater,
    int_greater_equal,

    int_load,
    int_store,

    int_to_float,
    int_to_ptr,

    // Float instructions
    float_push: f64,

    float_add,
    float_subtract,
    float_multiply,
    float_divide,
    float_modulo,

    float_equal,
    float_not_equal,

    float_less,
    float_less_equal,
    float_greater,
    float_greater_equal,

    float_load,
    float_store,

    float_to_int,

    // Boolean instructions
    bool_push: bool,

    bool_and,
    bool_or,
    bool_not,

    bool_equal,
    bool_not_equal,

    bool_load,
    bool_store,

    // Pointer instructions
    ptr_push: u64,

    ptr_add,
    ptr_subtract,

    ptr_equal,
    ptr_not_equal,

    ptr_to_int,

    // Block index instructions
    block_index_push: u32,

    // Branching
    call,
    conditional_call,

    // Stack manipulation
    drop,
    // TODO: Remove print instruction
    print,
};

pub const InstructionTag = enum(u8) {
    const Self = @This();
    // Int instructions
    int_push,

    int_add,
    int_subtract,
    int_multiply,
    int_divide,
    int_modulo,

    int_and,
    int_or,
    int_xor,
    int_not,
    int_shift_left,
    int_shift_right,

    int_equal,
    int_not_equal,

    int_less,
    int_less_equal,
    int_greater,
    int_greater_equal,

    int_load,
    int_store,

    int_to_float,
    int_to_ptr,

    // Float instructions
    float_push,

    float_add,
    float_subtract,
    float_multiply,
    float_divide,
    float_modulo,

    float_equal,
    float_not_equal,

    float_less,
    float_less_equal,
    float_greater,
    float_greater_equal,

    float_load,
    float_store,

    float_to_int,

    // Boolean instructions
    bool_push,

    bool_and,
    bool_or,
    bool_not,

    bool_equal,
    bool_not_equal,

    bool_load,
    bool_store,

    // Pointer instructions
    ptr_push,

    ptr_add,
    ptr_subtract,

    ptr_equal,
    ptr_not_equal,

    ptr_to_int,

    // Block index instructions
    block_index_push,

    // Branching
    call,
    conditional_call,

    // Stack manipulation
    drop,
    // TODO: Remove print instruction
    print,

    pub fn toInstruction(self: Self) Instruction {
        return switch (self) {
            .int_push => Instruction{ .int_push = undefined },
            .int_add => Instruction.int_add,
            .int_subtract => Instruction.int_subtract,
            .int_multiply => Instruction.int_multiply,
            .int_divide => Instruction.int_divide,
            .int_modulo => Instruction.int_modulo,
            .int_and => Instruction.int_and,
            .int_or => Instruction.int_or,
            .int_xor => Instruction.int_xor,
            .int_not => Instruction.int_not,
            .int_shift_left => Instruction.int_shift_right,
            .int_shift_right => Instruction.int_shift_right,
            .int_equal => Instruction.int_equal,
            .int_not_equal => Instruction.int_not_equal,
            .int_less => Instruction.int_less,
            .int_less_equal => Instruction.int_less_equal,
            .int_greater => Instruction.int_greater,
            .int_greater_equal => Instruction.int_greater_equal,
            .int_load => Instruction.int_load,
            .int_store => Instruction.int_store,
            .int_to_float => Instruction.int_to_float,
            .int_to_ptr => Instruction.int_to_ptr,
            .float_push => Instruction{ .float_push = undefined },
            .float_add => Instruction.float_add,
            .float_subtract => Instruction.float_subtract,
            .float_multiply => Instruction.float_multiply,
            .float_divide => Instruction.float_divide,
            .float_modulo => Instruction.float_modulo,
            .float_equal => Instruction.float_equal,
            .float_not_equal => Instruction.float_not_equal,
            .float_less => Instruction.float_less,
            .float_less_equal => Instruction.float_less_equal,
            .float_greater => Instruction.float_greater,
            .float_greater_equal => Instruction.float_greater_equal,
            .float_load => Instruction.float_load,
            .float_store => Instruction.float_store,
            .float_to_int => Instruction.float_to_int,
            .bool_push => Instruction{ .bool_push = undefined },
            .bool_and => Instruction.bool_and,
            .bool_or => Instruction.bool_or,
            .bool_equal => Instruction.bool_equal,
            .bool_not_equal => Instruction.bool_not_equal,
            .bool_not => Instruction.bool_not,
            .bool_load => Instruction.bool_load,
            .bool_store => Instruction.bool_store,
            .ptr_push => Instruction{ .ptr_push = undefined },
            .ptr_add => Instruction.ptr_add,
            .ptr_subtract => Instruction.ptr_subtract,
            .ptr_equal => Instruction.ptr_equal,
            .ptr_not_equal => Instruction.ptr_not_equals,
            .ptr_to_int => Instruction.ptr_to_int,
            .block_index_push => Instruction{ .block_index_push = undefined },
            .call => Instruction.call,
            .conditional_call => Instruction.conditional_call,
            .drop => Instruction.drop,
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
            .int_push => Instruction{ .int_push = try reader.readIntBig(u64) },
            .float_push => Instruction{ .float_push = @bitCast(f64, try reader.readBytesNoEof(@sizeOf(f64))) },
            .bool_push => Instruction{ .bool_push = try reader.readByte() != 0 },
            .ptr_push => Instruction{ .ptr_push = try reader.readIntBig(u64) },
            .block_index_push => Instruction{ .block_index_push = try reader.readIntBig(u32) },
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
            .int_push => |value| try writer.writeIntBig(u64, value),
            .float_push => |value| try writer.write(&@bitCast([@sizeOf(f64)]u8, value)),
            .bool_push => |value| try writer.writeByte(@boolToInt(value)),
            .ptr_push => |value| try writer.writeIntBig(u64, value),
            .block_index_push => |value| try writer.writeIntBig(u32, value),
            else => {},
        }
    }

    return byte_list.items;
}
