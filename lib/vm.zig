const std = @import("std");
const Allocator = std.mem.Allocator;

const assam = @import("assam.zig");
const Instruction = assam.Instruction;
const Value = assam.Value;
const BytecodeModule = assam.BytecodeModule;
const Block = assam.Block;

const BlockInstructionPointer = struct {
    block: Block,
    ip: u64, // Might be able to make this a `u32`
};

pub const VirtualMachine = struct {
    const Self = @This();

    module: BytecodeModule,
    data_stack: std.ArrayList(Value),
    call_stack: std.ArrayList(BlockInstructionPointer),
    global_memory: []u8,
    allocator: Allocator,

    pub fn init(module: BytecodeModule, allocator: Allocator) VirtualMachineError!Self {
        const global_memory = allocator.alloc(u8, module.global_memory_size) catch {
            return VirtualMachineError.OutOfMemory;
        };

        return Self{
            .module = module,
            .data_stack = std.ArrayList(Value).init(allocator),
            .call_stack = std.ArrayList(BlockInstructionPointer).init(allocator),
            .global_memory = global_memory,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Self) void {
        self.data_stack.deinit();
        self.call_stack.deinit();
        self.allocator.free(self.global_memory);
    }

    pub fn run(self: *Self) VirtualMachineError!void {
        try self.callBlock(self.module.start_block_index);
        while (self.call_stack.items.len != 0) {
            try self.executeNextInstruction();
        }
    }

    pub fn callBlock(self: *Self, block_index: u32) VirtualMachineError!void {
        if (block_index >= self.module.blocks.len) {
            return VirtualMachineError.InvalidBlockIndex;
        }

        const block_ip = BlockInstructionPointer{
            .block = self.module.blocks[block_index],
            .ip = 0,
        };
        self.call_stack.append(block_ip) catch {
            return VirtualMachineError.OutOfMemory;
        };
    }

    pub fn returnFromBlock(self: *Self) VirtualMachineError!void {
        if (self.call_stack.popOrNull() == null) {
            return VirtualMachineError.CallStackUnderflow;
        }
    }

    pub fn executeNextInstruction(self: *Self) VirtualMachineError!void {
        const block_ip = self.call_stack.items[self.call_stack.items.len - 1];
        if (block_ip.ip >= block_ip.block.len) {
            return self.returnFromBlock();
        }
        const instruction = block_ip.block[block_ip.ip];
        self.call_stack.items[self.call_stack.items.len - 1].ip += 1; // TODO: Remove this junk
        try self.executeInstruction(instruction);
    }

    pub fn executeInstruction(self: *Self, instruction: Instruction) VirtualMachineError!void {
        switch (instruction) {
            // Int instructions
            .int_push => |value| try self.pushInt(value),

            .int_add => try self.pushInt(try self.popInt() +% try self.popInt()),
            .int_subtract => {
                const b = try self.popInt();
                const a = try self.popInt();
                try self.pushInt(b -% a);
            },
            .int_multiply => try self.pushInt(try self.popInt() *% try self.popInt()),
            .int_divide => {
                const b = try self.popInt();
                if (b == 0) {
                    return VirtualMachineError.DivideByZero;
                }
                const a = try self.popInt();
                try self.pushInt(b / a);
            },
            .int_modulo => {
                const b = try self.popInt();
                if (b == 0) {
                    return VirtualMachineError.DivideByZero;
                }
                const a = try self.popInt();
                try self.pushInt(b % a);
            },

            .int_and => try self.pushInt(try self.popInt() & try self.popInt()),
            .int_or => try self.pushInt(try self.popInt() | try self.popInt()),
            .int_xor => try self.pushInt(try self.popInt() ^ try self.popInt()),
            .int_not => try self.pushInt(~try self.popInt()),
            .int_shift_left => {
                const shift_amount = try self.popInt();
                const value = try self.popInt();
                try self.pushInt(value << @intCast(u6, shift_amount));
            },
            .int_shift_right => {
                const shift_amount = try self.popInt();
                const value = try self.popInt();
                try self.pushInt(value >> @intCast(u6, shift_amount));
            },

            .int_equal => try self.pushBool(try self.popInt() == try self.popInt()),
            .int_not_equal => try self.pushBool(try self.popInt() != try self.popInt()),

            .int_less => {
                const b = try self.popInt();
                const a = try self.popInt();
                try self.pushBool(a < b);
            },
            .int_less_equal => {
                const b = try self.popInt();
                const a = try self.popInt();
                try self.pushBool(a <= b);
            },
            .int_greater => {
                const b = try self.popInt();
                const a = try self.popInt();
                try self.pushBool(a > b);
            },
            .int_greater_equal => {
                const b = try self.popInt();
                const a = try self.popInt();
                try self.pushBool(a >= b);
            },

            .int_load => {
                const offset = try self.popPtr();
                try self.assertBytesFitInMemory(@sizeOf(u64), offset);
                const value = std.mem.readIntNative(u64, self.global_memory[offset..][0..@sizeOf(u64)]);
                try self.pushInt(value);
            },
            .int_store => {
                const value = try self.popInt();
                const offset = try self.popPtr();
                try self.assertBytesFitInMemory(@sizeOf(u64), offset);
                std.mem.writeIntNative(u64, self.global_memory[offset..][0..@sizeOf(u64)], value);
            },

            .int_to_float => try self.pushFloat(@intToFloat(f64, try self.popInt())),
            .int_to_ptr => try self.pushPtr(try self.popInt()),

            // Float instructions
            .float_push => |value| try self.pushFloat(value),

            .float_add => try self.pushFloat(try self.popFloat() + try self.popFloat()),
            .float_subtract => {
                const b = try self.popFloat();
                const a = try self.popFloat();
                try self.pushFloat(a - b);
            },
            .float_multiply => try self.pushFloat(try self.popFloat() * try self.popFloat()),
            .float_divide => {
                const b = try self.popFloat();
                if (b == 0.0) {
                    return VirtualMachineError.DivideByZero;
                }
                const a = try self.popFloat();
                try self.pushFloat(a / b);
            },
            .float_modulo => {
                const b = try self.popFloat();
                if (b == 0.0) {
                    return VirtualMachineError.DivideByZero;
                }
                const a = try self.popFloat();
                try self.pushFloat(@mod(a, b));
            },

            .float_equal => try self.pushBool(try self.popFloat() == try self.popFloat()),
            .float_not_equal => try self.pushBool(try self.popFloat() != try self.popFloat()),

            .float_less => {
                const b = try self.popFloat();
                const a = try self.popFloat();
                try self.pushBool(a < b);
            },
            .float_less_equal => {
                const b = try self.popFloat();
                const a = try self.popFloat();
                try self.pushBool(a <= b);
            },
            .float_greater => {
                const b = try self.popFloat();
                const a = try self.popFloat();
                try self.pushBool(a > b);
            },
            .float_greater_equal => {
                const b = try self.popFloat();
                const a = try self.popFloat();
                try self.pushBool(a >= b);
            },

            .float_load => {
                const offset = try self.popInt();
                try self.assertBytesFitInMemory(@sizeOf(f64), offset);
                var buffer: [@sizeOf(f64)]u8 = undefined;
                std.mem.copy(u8, &buffer, self.global_memory[offset..][0..@sizeOf(f64)]);
                try self.pushFloat(@bitCast(f64, buffer));
            },
            .float_store => {
                const value = try self.popFloat();
                const offset = try self.popInt();
                try self.assertBytesFitInMemory(@sizeOf(f64), offset);
                std.mem.copy(u8, self.global_memory[offset..][0..@sizeOf(f64)], &@bitCast([@sizeOf(f64)]u8, value));
            },

            .float_to_int => try self.pushInt(@floatToInt(u64, try self.popFloat())),

            // Boolean instructions
            .bool_push => |value| try self.pushBool(value),

            .bool_and => {
                const b = try self.popBool();
                const a = try self.popBool();
                try self.pushBool(b and a);
            },
            .bool_or => {
                const b = try self.popBool();
                const a = try self.popBool();
                try self.pushBool(b or a);
            },
            .bool_not => try self.pushBool(!try self.popBool()),

            .bool_equal => try self.pushBool(try self.popBool() == try self.popBool()),
            .bool_not_equal => try self.pushBool(try self.popBool() != try self.popBool()),

            .bool_load => {
                const offset = try self.popInt();
                try self.assertBytesFitInMemory(@sizeOf(bool), offset);
                const byte = self.global_memory[offset];
                try self.pushBool(byte != 0);
            },
            .bool_store => {
                const value = try self.popBool();
                const offset = try self.popInt();
                try self.assertBytesFitInMemory(@sizeOf(bool), offset);
                self.global_memory[offset] = @boolToInt(value);
            },

            // Pointer instructions
            .ptr_push => |value| try self.pushPtr(value),

            .ptr_add => {
                const b = try self.popInt();
                const a = try self.popPtr();
                try self.pushPtr(a +% b);
            },
            .ptr_subtract => {
                const b = try self.popInt();
                const a = try self.popPtr();
                try self.pushPtr(a -% b);
            },

            .ptr_equal => try self.pushBool(try self.popPtr() == try self.popPtr()),
            .ptr_not_equal => try self.pushBool(try self.popPtr() != try self.popPtr()),

            .ptr_to_int => try self.pushInt(try self.popPtr()),

            // Branching
            .call => |block_index| try self.callBlock(block_index),
            .call_if => |block_index| {
                const condition = try self.popBool();
                if (condition) {
                    try self.callBlock(block_index);
                }
            },

            // Stack manipulation
            .drop => _ = try self.pop(),
            .dup => try self.push(try self.peek()),
            .swap => {
                const b = try self.pop();
                const a = try self.pop();
                try self.push(b);
                try self.push(a);
            },
            .over => {
                const b = try self.pop();
                const a = try self.pop();
                try self.push(a);
                try self.push(b);
                try self.push(a);
            },
            .rot => {
                const c = try self.pop();
                const b = try self.pop();
                const a = try self.pop();
                try self.push(b);
                try self.push(c);
                try self.push(a);
            },
            .block_return => try self.returnFromBlock(),
            .print => {
                const value = try self.pop();
                std.debug.print("{}\n", .{value});
            },
        }
    }

    fn push(self: *Self, value: Value) VirtualMachineError!void {
        self.data_stack.append(value) catch {
            return VirtualMachineError.OutOfMemory;
        };
    }

    fn pushInt(self: *Self, value: u64) VirtualMachineError!void {
        try self.push(Value{ .int = value });
    }

    fn pushFloat(self: *Self, value: f64) VirtualMachineError!void {
        try self.push(Value{ .float = value });
    }

    fn pushBool(self: *Self, value: bool) VirtualMachineError!void {
        try self.push(Value{ .bool = value });
    }

    fn pushPtr(self: *Self, address: u64) VirtualMachineError!void {
        try self.push(Value{ .ptr = address });
    }

    fn pop(self: *Self) VirtualMachineError!Value {
        return self.data_stack.popOrNull() orelse VirtualMachineError.StackUnderflow;
    }

    fn popInt(self: *Self) VirtualMachineError!u64 {
        const value = try self.pop();
        return switch (value) {
            .int => |inner_value| inner_value,
            else => VirtualMachineError.TypeError,
        };
    }

    fn popFloat(self: *Self) VirtualMachineError!f64 {
        const value = try self.pop();
        return switch (value) {
            .float => |inner_value| inner_value,
            else => VirtualMachineError.TypeError,
        };
    }

    fn popBool(self: *Self) VirtualMachineError!bool {
        const value = try self.pop();
        return switch (value) {
            .bool => |inner_value| inner_value,
            else => VirtualMachineError.TypeError,
        };
    }

    fn popPtr(self: *Self) VirtualMachineError!u64 {
        const value = try self.pop();
        return switch (value) {
            .ptr => |ptr| ptr,
            else => VirtualMachineError.TypeError,
        };
    }

    fn assertBytesFitInMemory(self: *Self, size: u64, offset: u64) VirtualMachineError!void {
        if (offset + size > self.global_memory.len) {
            return VirtualMachineError.InvalidGlobalOffset;
        }
    }

    fn peek(self: Self) !Value {
        if (self.data_stack.items.len == 0) {
            return VirtualMachineError.StackUnderflow;
        }
        return self.data_stack.items[self.data_stack.items.len - 1];
    }
};

pub const VirtualMachineError = error{
    OutOfMemory,
    StackUnderflow,
    CallStackUnderflow,
    DivideByZero,
    TypeError,
    MissingModule,
    InvalidBlockIndex,
    InvalidGlobalOffset,
    UnsupportedIntegerType,
};
