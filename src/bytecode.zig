const std = @import("std");
const mem = std.mem;
const Allocator = mem.Allocator;

const assam = @import("assam.zig");
const Instruction = assam.Instruction;
const InstructionTag = assam.InstructionTag;
const instructionsToBytes = assam.instructionsToBytes;
const instructionsFromBytes = assam.instructionsFromBytes;
const Value = assam.Value;
const ValueTag = assam.ValueTag;

pub const BytecodeModule = struct {
    const Self = @This();

    major_version: u8,
    minor_version: u8,
    patch_version: u8,
    instructions: []Instruction,

    pub fn fromBytes(bytes: []const u8, allocator: Allocator) !Self {
        var fbs = std.io.fixedBufferStream(bytes);
        var reader = fbs.reader();

        const signature = try reader.readBytesNoEof(3);
        if (!mem.eql(u8, &signature, "ABM")) {
            // TODO: Use custom error set
            return error.InvalidFileType;
        }

        var module: Self = undefined;
        module.major_version = try reader.readByte();
        module.minor_version = try reader.readByte();
        module.patch_version = try reader.readByte();

        const code_section = try reader.readAllAlloc(allocator, std.math.maxInt(u32));
        defer allocator.free(code_section);
        module.instructions = try instructionsFromBytes(code_section, allocator);

        return module;
    }

    pub fn toBytes(self: Self, allocator: Allocator) ![]u8 {
        var byte_list = std.ArrayList(u8).init(allocator);
        var writer = byte_list.writer();

        _ = try writer.write("ABM");
        try writer.writeByte(self.major_version);
        try writer.writeByte(self.minor_version);
        try writer.writeByte(self.patch_version);
        _ = try writer.write(try instructionsToBytes(self.instructions, allocator));

        return byte_list.items;
    }

    // Not sure if it makes sense to take an allocator as an argument here, but it seems to make more sense than
    // storing an allocator as an struct member to me. The downside of taking an allocator as an argument is that the
    // caller could potentially pass an allocator different from the one which was used to allocate the members we
    // argument freeing here
    pub fn deinit(self: Self, allocator: Allocator) void {
        allocator.free(self.instructions);
    }
};
