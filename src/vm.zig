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

    pub fn deinit(self: *Self) void {
        self.data_stack.deinit();
    }

    pub fn execute_instruction(self: *Self, instruction: Instruction) VirtualMachineError!void {
        return switch (instruction) {
            .Push => |value| try self.push(value),
            .Pop => _ = try self.pop(),
            .Dup => try self.push(try self.peek(-1)),
            .Over => try self.push(try self.peek(-2)),
            .Swap => {
                const a = try self.peek(-2);
                const b = try self.peek(-1);
                try self.replace(-2, b);
                try self.replace(-1, a);
            },
            .Rot => {
                const a = try self.peek(-3);
                const b = try self.peek(-2);
                const c = try self.peek(-1);
                try self.replace(-3, c);
                try self.replace(-2, a);
                try self.replace(-1, b);
            },
        };
    }

    pub fn get_snapshot(self: Self) VirtualMachineSnapshot {
        return VirtualMachineSnapshot{
            .data_stack = self.data_stack.items,
        };
    }

    fn push(self: *Self, value: Cell) VirtualMachineError!void {
        self.data_stack.append(value) catch {
            return VirtualMachineError.AllocationFailure;
        };
    }

    fn pop(self: *Self) VirtualMachineError!Cell {
        return self.data_stack.popOrNull() orelse VirtualMachineError.StackUnderflow;
    }

    fn peek(self: Self, index: isize) VirtualMachineError!Cell {
        const normal_index = try self.normalize_index(index);
        return self.data_stack.items[normal_index];
    }

    fn replace(self: *Self, index: isize, value: Cell) VirtualMachineError!void {
        const normal_index = try self.normalize_index(index);
        self.data_stack.items[normal_index] = value;
    }

    fn normalize_index(self: Self, index: isize) VirtualMachineError!usize {
        const stack_len = self.data_stack.items.len;
        var normal_index: usize = undefined;

        if (index < 0) {
            normal_index = stack_len - @intCast(usize, -index);
        } else {
            normal_index = @intCast(usize, index);
        }

        if (normal_index >= stack_len) {
            return VirtualMachineError.StackUnderflow;
        }

        return normal_index;
    }
};

pub const VirtualMachineError = error{
    AllocationFailure,
    StackUnderflow,
};

pub const VirtualMachineSnapshot = struct {
    data_stack: []Cell,
};
