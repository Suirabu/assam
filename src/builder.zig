const std = @import("std");
const Allocator = std.mem.Allocator;

const assam = @import("assam.zig");
const Instruction = assam.Instruction;
const BytecodeModule = assam.BytecodeModule;
const Block = assam.Block;

// TODO: Move to dedicated globals module
const major_version: u8 = 0;
const minor_version: u8 = 0;
const patch_version: u8 = 1;

pub const ModuleBuilder = struct {
    const Self = @This();

    allocator: Allocator,
    start_block_index: ?u32,
    next_block_builder_index: u32,
    block_builders: std.ArrayList(BlockBuilder),

    pub fn init(allocator: Allocator) Self {
        return Self{
            .allocator = allocator,
            .start_block_index = null,
            .next_block_builder_index = 0,
            .block_builders = std.ArrayList(BlockBuilder).init(allocator),
        };
    }

    pub fn deinit(self: *Self) void {
        for (self.block_builders.items) |*block_builder| {
            block_builder.deinit();
        }
        self.block_builders.deinit();
    }

    pub fn addBlock(self: *Self, block: BlockBuilder) !void {
        try self.block_builders.append(block);
    }

    pub fn setStartBlock(self: *Self, block_builder: BlockBuilder) void {
        self.start_block_index = block_builder.index;
    }

    // TODO: Use custom error set
    pub fn toBytecodeModule(self: *Self) !BytecodeModule {
        var module = BytecodeModule{
            .major_version = major_version,
            .minor_version = minor_version,
            .patch_version = patch_version,
            .start_block_index = undefined,
            .blocks = undefined,
        };

        // Blocks should be in order by default but you can never be *too* safe
        std.sort.sort(BlockBuilder, self.block_builders.items, {}, BlockBuilder.lessThan);
        // Verify block indices
        {
            var expected_index: u32 = 0;

            for (self.block_builders.items) |block_builder| {
                if (block_builder.index != expected_index) {
                    return error.UnexpectedBlockIndex;
                }
                expected_index += 1;
            }
        }

        var blocks = std.ArrayList(Block).init(self.allocator);
        defer blocks.deinit();

        for (self.block_builders.items) |*block_builder| {
            try blocks.append(try block_builder.toBlock());
        }
        module.blocks = try blocks.toOwnedSlice();

        if (self.start_block_index) |index| {
            module.start_block_index = index;
        } else {
            return error.MissingStartDefinition;
        }

        return module;
    }
};

pub const BlockBuilder = struct {
    const Self = @This();

    index: u32,
    instructions: std.ArrayList(Instruction),
    allocator: Allocator,

    pub fn init(context: *ModuleBuilder) Self {
        const index = context.next_block_builder_index;
        context.next_block_builder_index += 1;

        return Self{
            .index = index,
            .instructions = std.ArrayList(Instruction).init(context.allocator),
            .allocator = context.allocator,
        };
    }

    pub fn deinit(self: *Self) void {
        self.instructions.deinit();
    }

    pub fn appendInstruction(self: *Self, instruction: Instruction) !void {
        try self.instructions.append(instruction);
    }

    pub fn appendInstructions(self: *Self, instructions: []Instruction) !void {
        for (instructions) |instruction| {
            try self.appendInstruction(instruction);
        }
    }

    pub fn toBlock(self: *Self) !Block {
        return self.instructions.toOwnedSlice();
    }

    pub fn lessThan(context: void, lhs: Self, rhs: Self) bool {
        _ = context;
        return lhs.index < rhs.index;
    }
};
