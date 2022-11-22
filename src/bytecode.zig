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
    code: []const u8,

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

        // Get code section contents
        module.code = try reader.readAllAlloc(allocator, std.math.maxInt(u64));
        return module;
    }

    pub fn to_bytes(self: Self, allocator: Allocator) ![]const u8 {
        var byte_list = std.ArrayList(u8).init(allocator);
        var writer = byte_list.writer();

        std.debug.assert(try writer.write("ABF") == 3);
        try writer.writeByte(self.major_version);
        try writer.writeByte(self.minor_version);
        try writer.writeByte(self.patch_version);
        try writer.writeAll(self.code);

        return byte_list.items;
    }
};
