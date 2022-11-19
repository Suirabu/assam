const std = @import("std");
const mem = std.mem;
const io = std.io;
const Allocator = std.mem.Allocator;

const assam = @import("assam.zig");
const Instruction = assam.Instruction;
const InstructionTag = assam.InstructionTag;

pub const BytecodeModule = struct {
    const Self = @This();

    major_version: u8,
    minor_version: u8,
    patch_version: u8,
    instructions: []Instruction,

    pub fn from_bytes(bytes: []const u8, allocator: Allocator) !Self {
        var module: Self = undefined;

        var fbs = io.fixedBufferStream(bytes);
        var reader = fbs.reader();

        // Check file signature
        const signature = try reader.readBytesNoEof(3);
        if (!mem.eql(u8, &signature, "ABF")) {
            return error.InvalidSignature;
        }

        // Get version number
        module.major_version = try reader.readByte();
        module.minor_version = try reader.readByte();
        module.patch_version = try reader.readByte();

        var instruction_list = std.ArrayList(Instruction).init(allocator);

        // Decode instructions
        while (true) {
            // Attempt to read next byte, breaking out of our while loop if we have reached the end of `bytes`
            const opcode = reader.readByte() catch {
                break;
            };

            const tag = @intToEnum(InstructionTag, opcode);
            try instruction_list.append(switch (tag) {
                .Push => Instruction{ .Push = try reader.readIntBig(u64) },
                else => |tag| tag.as_instruction(),
            });
        }

        module.instructions = instruction_list.items;
        return module;
    }

    pub fn to_bytes(self: Self, allocator: Allocator) ![]const u8 {
        var byte_list = std.ArrayList(u8).init(allocator);
        var writer = byte_list.writer();

        std.debug.assert(try writer.write("ABF") == 3);
        try writer.writeByte(self.major_version);
        try writer.writeByte(self.minor_version);
        try writer.writeByte(self.patch_version);
        for (self.instructions) |instruction| {
            const tag: InstructionTag = instruction;
            try writer.writeByte(@enumToInt(tag));
            switch (instruction) {
                .Push => |value| try writer.writeIntBig(u64, value),
                else => {},
            }
        }

        return byte_list.items;
    }
};
