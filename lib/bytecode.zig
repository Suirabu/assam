const std = @import("std");
const mem = std.mem;
const Allocator = mem.Allocator;

const assam = @import("assam.zig");
const Instruction = assam.Instruction;
const Block = assam.Block;
const instructionsToBytes = assam.instructionsToBytes;
const instructionsFromBytes = assam.instructionsFromBytes;
const Value = assam.Value;

pub const BytecodeModule = struct {
    const Self = @This();

    major_version: u8,
    minor_version: u8,
    patch_version: u8,
    global_memory_size: u64,
    start_block_index: u32,
    blocks: []Block,

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
        module.global_memory_size = try reader.readIntBig(u64);

        // Parse code section
        module.start_block_index = try reader.readIntBig(u32);
        var blocks = std.ArrayList(Block).init(allocator);
        defer blocks.deinit();

        // Collect blocks
        while (true) {
            const block_size = reader.readIntBig(u32) catch break;

            var block_bytes = try allocator.alloc(u8, block_size);
            defer allocator.free(block_bytes);

            _ = try reader.read(block_bytes);

            const block = try instructionsFromBytes(block_bytes, allocator);
            try blocks.append(block);
        }

        module.blocks = try blocks.toOwnedSlice();

        return module;
    }

    pub fn toBytes(self: Self, allocator: Allocator) ![]u8 {
        var byte_list = std.ArrayList(u8).init(allocator);
        defer byte_list.deinit();
        var writer = byte_list.writer();

        _ = try writer.write("ABM");
        try writer.writeByte(self.major_version);
        try writer.writeByte(self.minor_version);
        try writer.writeByte(self.patch_version);
        try writer.writeIntBig(u64, self.global_memory_size);
        try writer.writeIntBig(u32, self.start_block_index);

        for (self.blocks) |block| {
            const bytes = try instructionsToBytes(block, allocator);
            defer allocator.free(bytes);
            try writer.writeIntBig(u32, @intCast(u32, bytes.len));
            _ = try writer.write(bytes);
        }

        return byte_list.toOwnedSlice();
    }

    // Not sure if it makes sense to take an allocator as an argument here, but it seems to make more sense than
    // storing an allocator as an struct member to me. The downside of taking an allocator as an argument is that the
    // caller could potentially pass an allocator different from the one which was used to allocate the members we
    // argument freeing here
    pub fn deinit(self: Self, allocator: Allocator) void {
        for (self.blocks) |block| {
            allocator.free(block);
        }
        allocator.free(self.blocks);
    }
};
