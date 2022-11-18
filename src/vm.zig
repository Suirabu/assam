const std = @import("std");
const Allocator = std.mem.Allocator;

const assam = @import("assam.zig");
const Cell = assam.Cell;
const Instruction = assam.Instruction;

const CellArrayList = std.ArrayList(Cell);

pub const VirtualMachine = struct {
    const Self = @This();

    data_stack: CellArrayList,
    allocator: Allocator,

    pub fn init(allocator: Allocator) Self {
        return Self{
            .data_stack = CellArrayList.init(allocator),
            .allocator = allocator,
        };
    }

    pub fn execute_instruction(self: *Self, instruction: Instruction) VirtualMachineError!void {
        return switch (instruction) {
            .Push => |value| {
                self.data_stack.append(value) catch {
                    return VirtualMachineError.AllocationFailure;
                };
            },
            .Pop => {
                _ = self.data_stack.popOrNull() orelse {
                    return VirtualMachineError.StackUnderflow;
                };
            },
        };
    }

    pub fn deinit(self: *Self) void {
        self.data_stack.deinit();
    }
};

pub const VirtualMachineError = error{
    AllocationFailure,
    StackUnderflow,
};
