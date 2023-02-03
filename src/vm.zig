const std = @import("std");
const Allocator = std.mem.Allocator;

const assam = @import("assam.zig");
const Instruction = assam.Instruction;
const Value = assam.Value;
const ValueTag = assam.ValueTag;
const BytecodeModule = assam.BytecodeModule;

pub const VirtualMachine = struct {
    const Self = @This();

    module: BytecodeModule,
    data_stack: std.ArrayList(Value),
    global_memory: []u8,
    allocator: Allocator,

    pub fn init(module: BytecodeModule, allocator: Allocator) VirtualMachineError!Self {
        const global_memory = allocator.alloc(u8, module.global_memory_size) catch {
            return VirtualMachineError.OutOfMemory;
        };

        return Self{
            .module = module,
            .data_stack = std.ArrayList(Value).init(allocator),
            .global_memory = global_memory,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Self) void {
        self.data_stack.deinit();
        self.allocator.free(self.global_memory);
    }

    pub fn run(self: *Self) VirtualMachineError!void {
        for (self.module.blocks[self.module.start_block_index]) |instruction| {
            try self.executeInstruction(instruction);
        }
    }

    pub fn executeInstruction(self: *Self, instruction: Instruction) VirtualMachineError!void {
        switch (instruction) {
            // Stack operations
            .push => |value| try self.push(value),
            .drop => _ = try self.pop(),

            // Arithmetic operations
            .add => {
                const pair = try self.popNativeIntPair();
                try self.pushNativeInt(pair.priority_tag, pair.a +% pair.b);
            },
            .subtract => {
                const pair = try self.popNativeIntPair();
                try self.pushNativeInt(pair.priority_tag, pair.a -% pair.b);
            },
            .multiply => {
                const pair = try self.popIntPair();
                try self.pushInt(pair.priority_tag, pair.a *% pair.b);
            },
            .divide => {
                const pair = try self.popIntPair();
                if (pair.b == 0) {
                    return VirtualMachineError.DivideByZero;
                }
                try self.pushInt(pair.priority_tag, pair.a / pair.b);
            },
            .modulo => {
                const pair = try self.popIntPair();
                if (pair.b == 0) {
                    return VirtualMachineError.DivideByZero;
                }
                try self.pushInt(pair.priority_tag, pair.a % pair.b);
            },

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

            // Bitwise operations
            .bitwise_and => {
                const pair = try self.popIntPair();
                try self.pushInt(pair.priority_tag, pair.a & pair.b);
            },
            .bitwise_or => {
                const pair = try self.popIntPair();
                try self.pushInt(pair.priority_tag, pair.a | pair.b);
            },
            .bitwise_xor => {
                const pair = try self.popIntPair();
                try self.pushInt(pair.priority_tag, pair.a ^ pair.b);
            },
            .bitwise_not => {
                const value = try self.pop();
                if (!value.isInt()) {
                    return VirtualMachineError.TypeError;
                }
                try self.pushInt(value, ~value.toInt());
            },
            .shift_left => {
                const pair = try self.popIntPair();
                try self.pushInt(pair.priority_tag, pair.a << @intCast(u6, pair.b));
            },
            .shift_right => {
                const pair = try self.popIntPair();
                try self.pushInt(pair.priority_tag, pair.a >> @intCast(u6, pair.b));
            },

            // Logical operations
            .logical_and => {
                const b = try self.popBool();
                const a = try self.popBool();
                try self.pushBool(b and a);
            },
            .logical_or => {
                const b = try self.popBool();
                const a = try self.popBool();
                try self.pushBool(b or a);
            },
            .logical_not => try self.pushBool(!try self.popBool()),
            .equal => {
                const b = try self.pop();
                const a = try self.pop();
                try assertEqualTypes(a, b);
                try self.pushBool(a.eql(b));
            },
            .not_equal => {
                const b = try self.pop();
                const a = try self.pop();
                try assertEqualTypes(a, b);
                try self.pushBool(!a.eql(b));
            },
            .less => {
                const b = try self.popNativeInt();
                const a = try self.popNativeInt();
                try self.pushBool(a < b);
            },
            .less_equal => {
                const b = try self.popNativeInt();
                const a = try self.popNativeInt();
                try self.pushBool(a <= b);
            },
            .greater => {
                const b = try self.popNativeInt();
                const a = try self.popNativeInt();
                try self.pushBool(a > b);
            },
            .greater_equal => {
                const b = try self.popNativeInt();
                const a = try self.popNativeInt();
                try self.pushBool(a >= b);
            },
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
            .call => {
                const block_index = try self.popBlockIndex();
                if (block_index >= self.module.blocks.len) {
                    return VirtualMachineError.InvalidBlockIndex;
                }

                for (self.module.blocks[block_index]) |i| {
                    try self.executeInstruction(i);
                }
            },
            .conditional_call => {
                const condition = try self.popBool();
                const block_index = try self.popBlockIndex();
                if (block_index >= self.module.blocks.len) {
                    return VirtualMachineError.InvalidBlockIndex;
                }

                if (!condition) {
                    return;
                }

                for (self.module.blocks[block_index]) |i| {
                    try self.executeInstruction(i);
                }
            },
            .load_int => {
                const offset = try self.popPointer();
                try self.assertBytesFitInMemory(@sizeOf(u64), offset);
                const value = std.mem.readIntNative(u64, self.global_memory[offset..][0..@sizeOf(u64)]);
                try self.pushInt(.int, value);
            },
            .load_float => {
                const offset = try self.popInt();
                try self.assertBytesFitInMemory(@sizeOf(f64), offset);
                var buffer: [@sizeOf(f64)]u8 = undefined;
                std.mem.copy(u8, &buffer, self.global_memory[offset..][0..@sizeOf(f64)]);
                try self.pushFloat(@bitCast(f64, buffer));
            },
            .load_bool => {
                const offset = try self.popInt();
                try self.assertBytesFitInMemory(@sizeOf(bool), offset);
                const byte = self.global_memory[offset];
                try self.pushBool(byte != 0);
            },
            .store_int => {
                const value = try self.popInt();
                const offset = try self.popPointer();
                try self.assertBytesFitInMemory(@sizeOf(u64), offset);
                std.mem.writeIntNative(u64, self.global_memory[offset..][0..@sizeOf(u64)], value);
            },
            .store_float => {
                const value = try self.popFloat();
                const offset = try self.popInt();
                try self.assertBytesFitInMemory(@sizeOf(f64), offset);
                std.mem.copy(u8, self.global_memory[offset..][0..@sizeOf(f64)], &@bitCast([@sizeOf(f64)]u8, value));
            },
            .store_bool => {
                const value = try self.popBool();
                const offset = try self.popInt();
                try self.assertBytesFitInMemory(@sizeOf(bool), offset);
                self.global_memory[offset] = @boolToInt(value);
            },
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

    fn pushBlockIndex(self: *Self, block_index: u32) VirtualMachineError!void {
        try self.push(Value{ .block_index = block_index });
    }

    fn pushPointer(self: *Self, address: u32) VirtualMachineError!void {
        try self.push(Value{ .pointer = address });
    }

    /// Pushes a native integer with type `tag` onto the stack
    fn pushNativeInt(self: *Self, tag: ValueTag, value: u64) VirtualMachineError!void {
        try self.push(switch (tag) {
            .block_index => Value{ .block_index = @intCast(u32, value) },
            .pointer => Value{ .pointer = @intCast(u32, value) },
            .int => Value{ .int = value },
            else => return VirtualMachineError.TypeError,
        });
    }

    /// Pushes an integer with type `tag` onto the stack
    fn pushInt(self: *Self, tag: ValueTag, value: u64) VirtualMachineError!void {
        try self.push(switch (tag) {
            .int => Value{ .int = value },
            else => return VirtualMachineError.TypeError,
        });
    }

    fn pushFloat(self: *Self, value: f64) VirtualMachineError!void {
        try self.push(Value{ .float = value });
    }

    fn pushBool(self: *Self, value: bool) VirtualMachineError!void {
        try self.push(Value{ .bool = value });
    }

    fn pop(self: *Self) VirtualMachineError!Value {
        return self.data_stack.popOrNull() orelse VirtualMachineError.StackUnderflow;
    }

    fn popBlockIndex(self: *Self) VirtualMachineError!u32 {
        const value = try self.pop();
        return switch (value) {
            .block_index => |block_index| block_index,
            else => VirtualMachineError.TypeError,
        };
    }

    fn popPointer(self: *Self) VirtualMachineError!u32 {
        const value = try self.pop();
        return switch (value) {
            .pointer => |pointer| pointer,
            else => VirtualMachineError.TypeError,
        };
    }

    /// Pops and returns a pair of native integers from the stack along with their priority int tag
    fn popNativeIntPair(self: *Self) VirtualMachineError!struct { a: u64, b: u64, priority_tag: ValueTag } {
        const b = try self.pop();
        const a = try self.pop();
        if (!a.isNativeInt() or !b.isNativeInt()) {
            return VirtualMachineError.TypeError;
        }
        const priority_tag = try Value.getPriorityIntTag(a, b);
        return .{
            .a = a.toInt(),
            .b = b.toInt(),
            .priority_tag = priority_tag,
        };
    }

    /// Pops and returns a pair of integers from the stack along with their priority int tag
    fn popIntPair(self: *Self) VirtualMachineError!struct { a: u64, b: u64, priority_tag: ValueTag } {
        const b = try self.pop();
        const a = try self.pop();
        if (!a.isInt() or !b.isInt()) {
            return VirtualMachineError.TypeError;
        }
        const priority_tag = try Value.getPriorityIntTag(a, b);
        return .{
            .a = a.toInt(),
            .b = b.toInt(),
            .priority_tag = priority_tag,
        };
    }

    fn popNativeInt(self: *Self) VirtualMachineError!u64 {
        const value = try self.pop();
        if (!value.isInt()) {
            return VirtualMachineError.TypeError;
        }
        return value.toInt();
    }

    fn popInt(self: *Self) VirtualMachineError!u64 {
        const value = try self.pop();
        if (!value.isInt()) {
            return VirtualMachineError.TypeError;
        }
        return value.toInt();
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

    fn assertBytesFitInMemory(self: *Self, size: u64, offset: u64) VirtualMachineError!void {
        if (offset + size > self.global_memory.len) {
            return VirtualMachineError.InvalidGlobalOffset;
        }
    }

    fn assertEqualTypes(a: Value, b: Value) VirtualMachineError!void {
        const a_tag: ValueTag = a;
        const b_tag: ValueTag = b;
        if (a_tag != b_tag) {
            return VirtualMachineError.TypeError;
        }
    }
};

pub const VirtualMachineError = error{
    OutOfMemory,
    StackUnderflow,
    DivideByZero,
    TypeError,
    MissingModule,
    InvalidBlockIndex,
    InvalidGlobalOffset,
    UnsupportedIntegerType,
};
