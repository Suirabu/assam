const std = @import("std");
const Allocator = std.mem.Allocator;

const assam = @import("assam");
const Instruction = assam.Instruction;
const BytecodeModule = assam.BytecodeModule;
const ModuleBuilder = assam.ModuleBuilder;
const BlockBuilder = assam.BlockBuilder;

// TODO: Report location in error messages
pub const Assembler = struct {
    const Self = @This();

    lexemme_iter: std.mem.TokenIterator(u8),
    ptr_map: std.StringHashMap(u64),
    block_map: std.StringHashMap(u32),
    blocks: std.ArrayList(BlockBuilder),
    entry_block_identifier: ?[]const u8,
    module_builder: ModuleBuilder,
    allocator: Allocator,

    pub fn init(source: []const u8, allocator: Allocator) Self {
        var module_builder = ModuleBuilder.init(allocator);

        return Self{
            .lexemme_iter = std.mem.tokenize(u8, source, " \t\r\n"),
            .ptr_map = std.StringHashMap(u64).init(allocator),
            .block_map = std.StringHashMap(u32).init(allocator),
            .blocks = std.ArrayList(BlockBuilder).init(allocator),
            .entry_block_identifier = null,
            .module_builder = module_builder,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Self) void {
        self.ptr_map.deinit();
        self.block_map.deinit();
        self.module_builder.deinit();
        for (self.blocks.items) |*block| {
            block.deinit();
        }
        self.blocks.deinit();
    }

    pub fn assembleFromSource(self: *Self) !BytecodeModule {
        while (self.lexemme_iter.next()) |lexemme| {
            if (std.mem.eql(u8, lexemme, "entry")) {
                self.entry_block_identifier = try self.expectLexemme("identifier");
            } else if (std.mem.eql(u8, lexemme, "block")) {
                try self.collectBlock();
            } else if (std.mem.eql(u8, lexemme, "global")) {
                try self.collectGlobalDefinition();
            } else {
                std.log.err("invalid lexemme '{s}'", .{lexemme});
                return error.InvalidLexemme;
            }
        }

        return self.module_builder.toBytecodeModule();
    }

    fn collectBlock(self: *Self) !void {
        var block_builder = BlockBuilder.init(&self.module_builder);

        const identifier = try self.expectLexemme("identifier");
        if (self.block_map.get(identifier)) |_| {
            std.log.err("redefinition of '{s}'", .{identifier});
            return error.IdentifierRedefinition;
        }
        if (self.ptr_map.get(identifier)) |_| {
            std.log.err("redefinition of '{s}'", .{identifier});
            return error.IdentifierRedefinition;
        }
        try self.block_map.put(identifier, block_builder.index);
        try self.blocks.append(block_builder);

        while (self.lexemme_iter.peek() != null and !std.mem.eql(u8, self.lexemme_iter.peek().?, "end")) {
            const instruction = try self.collectInstruction();
            try block_builder.appendInstruction(instruction);
        }
        _ = try self.expectLexemme("token 'end'");

        try self.module_builder.addBlock(block_builder);
        if (self.entry_block_identifier) |entry_block_identifier| {
            if (std.mem.eql(u8, identifier, entry_block_identifier)) {
                self.module_builder.setStartBlock(block_builder);
            }
        }
    }

    fn collectGlobalDefinition(self: *Self) !void {
        const ty = try self.expectLexemme("type");

        const identifier = try self.expectLexemme("identifier");
        if (self.block_map.get(identifier)) |_| {
            std.log.err("redefinition of '{s}'", .{identifier});
            return error.IdentifierRedefinition;
        }
        if (self.ptr_map.get(identifier)) |_| {
            std.log.err("redefinition of '{s}'", .{identifier});
            return error.IdentifierRedefinition;
        }

        var addr: u64 = undefined;

        if (std.mem.eql(u8, ty, "int")) {
            addr = self.module_builder.allocateGlobalInt();
        } else if (std.mem.eql(u8, ty, "float")) {
            addr = self.module_builder.allocateGlobalFloat();
        } else if (std.mem.eql(u8, ty, "bool")) {
            addr = self.module_builder.allocateGlobalBool();
        } else if (std.mem.eql(u8, ty, "bytes")) {
            const n_bytes = try self.collectInt();
            addr = self.module_builder.allocateGlobalBytes(n_bytes);
        } else {
            std.log.err("invalid type '{s}'", .{ty});
            return error.InvalidType;
        }

        try self.ptr_map.put(identifier, addr);
    }

    fn collectInstruction(self: *Self) !Instruction {
        const lexemme = self.lexemme_iter.next().?;
        if (!lexemme_map.has(lexemme)) {
            std.log.err("expected instruction, found '{s}' instead", .{lexemme});
            return error.InvalidLexemme;
        }
        var instruction = lexemme_map.get(lexemme).?;
        instruction = switch (instruction) {
            .int_push => Instruction{ .int_push = try self.collectInt() },
            .float_push => Instruction{ .float_push = try self.collectFloat() },
            .bool_push => Instruction{ .bool_push = try self.collectBool() },
            .ptr_push => Instruction{ .ptr_push = try self.collectPtr() },
            .call => Instruction{ .call = try self.collectBlockIndex() },
            .call_if => Instruction{ .call_if = try self.collectBlockIndex() },
            else => instruction,
        };
        return instruction;
    }

    fn collectBlockIndex(self: *Self) !u32 {
        const lexemme = try self.expectLexemme("block");
        return self.block_map.get(lexemme) orelse {
            std.log.err("no block named '{s}' exists", .{lexemme});
            return error.UnexpectedLexemme;
        };
    }

    fn collectPtr(self: *Self) !u64 {
        const lexemme = try self.expectLexemme("ptr");
        return self.ptr_map.get(lexemme) orelse {
            std.log.err("no ptr named '{s}' exists", .{lexemme});
            return error.UnexpectedLexemme;
        };
    }

    fn collectBool(self: *Self) !bool {
        const lexemme = try self.expectLexemme("boolean literal");
        if (std.mem.eql(u8, lexemme, "true")) {
            return true;
        } else if (std.mem.eql(u8, lexemme, "false")) {
            return false;
        }

        std.log.err("failed to parse '{s}' as boolean literal", .{lexemme});
        return error.UnexpectedLexemme;
    }

    fn collectFloat(self: *Self) !f64 {
        const lexemme = try self.expectLexemme("float literal");
        return std.fmt.parseFloat(f64, lexemme) catch {
            std.log.err("failed to parse '{s}' as float literal", .{lexemme});
            return error.UnexpectedLexemme;
        };
    }

    fn collectInt(self: *Self) !u64 {
        const lexemme = try self.expectLexemme("integer literal");
        return std.fmt.parseInt(u64, lexemme, 10) catch {
            std.log.err("failed to parse '{s}' as integer literal", .{lexemme});
            return error.UnexpectedLexemme;
        };
    }

    fn expectLexemme(self: *Self, lexemme_description: []const u8) ![]const u8 {
        return self.lexemme_iter.next() orelse {
            std.log.err("expected {s}, found end-of-file instead", .{lexemme_description});
            return error.ExpectedLexemme;
        };
    }

    const lexemme_map = std.ComptimeStringMap(assam.Instruction, .{
        .{ "int.push", Instruction{ .int_push = undefined } },
        .{ "int.add", Instruction.int_add },
        .{ "int.subtract", Instruction.int_subtract },
        .{ "int.multiply", Instruction.int_multiply },
        .{ "int.divide", Instruction.int_divide },
        .{ "int.modulo", Instruction.int_modulo },
        .{ "int.and", Instruction.int_and },
        .{ "int.or", Instruction.int_or },
        .{ "int.xor", Instruction.int_xor },
        .{ "int.not", Instruction.int_not },
        .{ "int.shift_left", Instruction.int_shift_right },
        .{ "int.shift_right", Instruction.int_shift_right },
        .{ "int.equal", Instruction.int_equal },
        .{ "int.not_equal", Instruction.int_not_equal },
        .{ "int.less", Instruction.int_less },
        .{ "int.less_equal", Instruction.int_less_equal },
        .{ "int.greater", Instruction.int_greater },
        .{ "int.greater_equal", Instruction.int_greater_equal },
        .{ "int.load", Instruction.int_load },
        .{ "int.store", Instruction.int_store },
        .{ "int.to_float", Instruction.int_to_float },
        .{ "int.to_ptr", Instruction.int_to_ptr },
        .{ "float.push", Instruction{ .float_push = undefined } },
        .{ "float.add", Instruction.float_add },
        .{ "float.subtract", Instruction.float_subtract },
        .{ "float.multiply", Instruction.float_multiply },
        .{ "float.divide", Instruction.float_divide },
        .{ "float.modulo", Instruction.float_modulo },
        .{ "float.equal", Instruction.float_equal },
        .{ "float.not_equal", Instruction.float_not_equal },
        .{ "float.less", Instruction.float_less },
        .{ "float.less_equal", Instruction.float_less_equal },
        .{ "float.greater", Instruction.float_greater },
        .{ "float.greater_equal", Instruction.float_greater_equal },
        .{ "float.load", Instruction.float_load },
        .{ "float.store", Instruction.float_store },
        .{ "float.to_int", Instruction.float_to_int },
        .{ "bool.push", Instruction{ .bool_push = undefined } },
        .{ "bool.and", Instruction.bool_and },
        .{ "bool.or", Instruction.bool_or },
        .{ "bool.equal", Instruction.bool_equal },
        .{ "bool.not_equal", Instruction.bool_not_equal },
        .{ "bool.not", Instruction.bool_not },
        .{ "bool.load", Instruction.bool_load },
        .{ "bool.store", Instruction.bool_store },
        .{ "ptr.push", Instruction{ .ptr_push = undefined } },
        .{ "ptr.add", Instruction.ptr_add },
        .{ "ptr.subtract", Instruction.ptr_subtract },
        .{ "ptr.equal", Instruction.ptr_equal },
        .{ "ptr.not_equal", Instruction.ptr_not_equal },
        .{ "ptr.to_int", Instruction.ptr_to_int },
        .{ "call", Instruction{ .call = undefined } },
        .{ "call_if", Instruction{ .call_if = undefined } },
        .{ "drop", Instruction.drop },
        .{ "dup", Instruction.dup },
        .{ "swap", Instruction.swap },
        .{ "over", Instruction.over },
        .{ "rot", Instruction.rot },
        .{ "print", Instruction.print },
    });
};
