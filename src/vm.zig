const std = @import("std");
const Allocator = std.mem.Allocator;

const assam = @import("assam.zig");
const Instruction = assam.Instruction;

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
            // Stack operations
            .Push => |value| try self.push(value),
            .Drop => _ = try self.pop(),

            // Arithmetic operations
            .Add => try self.push(try self.pop() +% try self.pop()),
            .Subtract => {
                const b = try self.pop();
                const a = try self.pop();
                try self.push(a -% b);
            },
            .Multiply => try self.push(try self.pop() *% try self.pop()),
            .Divide => {
                const b = try self.pop();
                if (b == 0) {
                    return VirtualMachineError.DivideByZero;
                }
                const a = try self.pop();
                try self.push(a / b);
            },
            .Modulo => {
                const b = try self.pop();
                if (b == 0) {
                    return VirtualMachineError.DivideByZero;
                }
                const a = try self.pop();
                try self.push(a % b);
            },
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
    DivideByZero,
};
