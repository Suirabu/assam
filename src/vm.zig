const std = @import("std");
const Allocator = std.mem.Allocator;

const Instruction = @import("instruction.zig").Instruction;

pub const VirtualMachine = struct {
    const Self = @This();

    data_stack: std.ArrayList(u64),
    allocator: Allocator,

    pub fn init(allocator: Allocator) Self {
        return Self{
            .data_stack = std.ArrayList(u64).init(allocator),
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Self) void {
        self.data_stack.deinit();
    }

    pub fn executeInstruction(self: *Self, instruction: Instruction) VirtualMachineError!void {
        switch (instruction) {
            .Push => |value| try self.push(value),
            .Drop => _ = try self.pop(),
        }
    }

    fn push(self: *Self, value: u64) VirtualMachineError!void {
        self.data_stack.append(value) catch {
            return VirtualMachineError.OutOfMemory;
        };
    }

    fn pop(self: *Self) VirtualMachineError!u64 {
        return self.data_stack.popOrNull() orelse VirtualMachineError.StackUnderflow;
    }
};

pub const VirtualMachineError = error{
    OutOfMemory,
    StackUnderflow,
};
