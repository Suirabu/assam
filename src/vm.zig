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
            .Push => |value| try self.push(value),
            .Drop => _ = try self.pop(),

            // Arithmetic operations
            .Add => try self.pushInt(try self.popInt() +% try self.popInt()),
            .Subtract => {
                const b = try self.popInt();
                const a = try self.popInt();
                try self.pushInt(a -% b);
            },
            .Multiply => try self.pushInt(try self.popInt() *% try self.popInt()),
            .Divide => {
                const b = try self.popInt();
                if (b == 0) {
                    return VirtualMachineError.DivideByZero;
                }
                const a = try self.popInt();
                try self.pushInt(a / b);
            },
            .Modulo => {
                const b = try self.popInt();
                if (b == 0) {
                    return VirtualMachineError.DivideByZero;
                }
                const a = try self.popInt();
                try self.pushInt(a % b);
            },

            // Bitwise operations
            .BitwiseAnd => try self.pushInt(try self.popInt() & try self.popInt()),
            .BitwiseOr => try self.pushInt(try self.popInt() | try self.popInt()),
            .BitwiseXor => try self.pushInt(try self.popInt() ^ try self.popInt()),
            .BitwiseNot => try self.pushInt(~try self.popInt()),
            .ShiftLeft => {
                const b = try self.popInt();
                const a = try self.popInt();
                try self.pushInt(a << @intCast(u6, b));
            },
            .ShiftRight => {
                const b = try self.popInt();
                const a = try self.popInt();
                try self.pushInt(a << @intCast(u6, b));
            },

            // Logical operations
            .LogicalAnd => {
                const b = try self.popBool();
                const a = try self.popBool();
                try self.pushBool(b and a);
            },
            .LogicalOr => {
                const b = try self.popBool();
                const a = try self.popBool();
                try self.pushBool(b or a);
            },
            .LogicalNot => try self.pushBool(!try self.popBool()),
            .Equal => {
                const b = try self.pop();
                const a = try self.pop();
                try assertEqualTypes(a, b);
                try self.pushBool(a.eql(b));
            },
            .NotEqual => {
                const b = try self.pop();
                const a = try self.pop();
                try assertEqualTypes(a, b);
                try self.pushBool(!a.eql(b));
            },
            .Less => {
                const b = try self.popInt();
                const a = try self.popInt();
                try self.pushBool(a < b);
            },
            .LessEqual => {
                const b = try self.popInt();
                const a = try self.popInt();
                try self.pushBool(a <= b);
            },
            .Greater => {
                const b = try self.popInt();
                const a = try self.popInt();
                try self.pushBool(a > b);
            },
            .GreaterEqual => {
                const b = try self.popInt();
                const a = try self.popInt();
                try self.pushBool(a >= b);
            },
            .Call => {
                const block_index = try self.popBlockIndex();
                if (block_index >= self.module.blocks.len) {
                    return VirtualMachineError.InvalidBlockIndex;
                }

                for (self.module.blocks[block_index]) |i| {
                    try self.executeInstruction(i);
                }
            },
            .ConditionalCall => {
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
            .LoadInt => {
                const offset = try self.popInt();
                try self.assertBytesFitInMemory(@sizeOf(u64), offset);
                const value = std.mem.readIntNative(u64, self.global_memory[offset..][0..@sizeOf(u64)]);
                try self.pushInt(value);
            },
            .LoadBool => {
                const offset = try self.popInt();
                try self.assertBytesFitInMemory(@sizeOf(bool), offset);
                const byte = self.global_memory[offset];
                try self.pushBool(byte != 0);
            },
            .StoreInt => {
                const value = try self.popInt();
                const offset = try self.popInt();
                try self.assertBytesFitInMemory(@sizeOf(u64), offset);
                std.mem.writeIntNative(u64, self.global_memory[offset..][0..@sizeOf(u64)], value);
            },
            .StoreBool => {
                const value = try self.popBool();
                const offset = try self.popInt();
                try self.assertBytesFitInMemory(@sizeOf(bool), offset);
                self.global_memory[offset] = @boolToInt(value);
            },
            .Print => {
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
        try self.push(Value{ .BlockIndex = block_index });
    }

    fn pushInt(self: *Self, value: u64) VirtualMachineError!void {
        try self.push(Value{ .Int = value });
    }

    fn pushBool(self: *Self, value: bool) VirtualMachineError!void {
        try self.push(Value{ .Bool = value });
    }

    fn pop(self: *Self) VirtualMachineError!Value {
        return self.data_stack.popOrNull() orelse VirtualMachineError.StackUnderflow;
    }

    fn popBlockIndex(self: *Self) VirtualMachineError!u32 {
        const value = try self.pop();
        return switch (value) {
            .BlockIndex => |block_index| block_index,
            else => VirtualMachineError.TypeError,
        };
    }

    fn popInt(self: *Self) VirtualMachineError!u64 {
        const value = try self.pop();
        return switch (value) {
            .Int => |inner_value| inner_value,
            else => VirtualMachineError.TypeError,
        };
    }

    fn popBool(self: *Self) VirtualMachineError!bool {
        const value = try self.pop();
        return switch (value) {
            .Bool => |inner_value| inner_value,
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
};
