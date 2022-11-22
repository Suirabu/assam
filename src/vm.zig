const std = @import("std");
const Allocator = std.mem.Allocator;

const assam = @import("assam.zig");
const Cell = assam.Cell;
const InstructionTag = assam.InstructionTag;

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

    pub fn execute_code(self: *Self, code: []const u8) VirtualMachineError!void {
        var code_buffer_stream = std.io.fixedBufferStream(code);
        var code_reader = code_buffer_stream.reader();

        while(true) {
            switch (code_reader.readEnum(InstructionTag, std.builtin.Endian.Big) catch break) {
                // Meta operations
                .Halt => return,

                // Stack operations
                .Push => {
                    const value = code_reader.readIntBig(Cell) catch {
                        return VirtualMachineError.ParseIntFailure;
                    };
                    try self.push(value);
                },
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
                    const a = try self.pop();
                    try self.push(a / b);
                },
                .Modulo => {
                    const b = try self.pop();
                    const a = try self.pop();
                    try self.push(a % b);
                },
                // Logical operations
                .Equal => try self.push(@boolToInt(try self.pop() == try self.pop())),
                .Less => {
                    const b = try self.pop();
                    const a = try self.pop();
                    try self.push(@boolToInt(a < b));
                },
                .LessEqual => {
                    const b = try self.pop();
                    const a = try self.pop();
                    try self.push(@boolToInt(a <= b));
                },
                .Greater => {
                    const b = try self.pop();
                    const a = try self.pop();
                    try self.push(@boolToInt(a > b));
                },
                .GreaterEqual => {
                    const b = try self.pop();
                    const a = try self.pop();
                    try self.push(@boolToInt(a >= b));
                },
                .And => {
                    const a = try self.popBool();
                    const b = try self.popBool();
                    try self.push(if (a and b) 1 else 0);
                },
                .Or => {
                    const a = try self.popBool();
                    const b = try self.popBool();
                    try self.push(if (a or b) 1 else 0);
                },
                .Not => try self.push(@boolToInt(!try self.popBool())),
            }
        }
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

    fn popBool(self: *Self) VirtualMachineError!bool {
        return try self.pop() != 0;
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
    ParseIntFailure,
    StackUnderflow,
};

pub const VirtualMachineSnapshot = struct {
    data_stack: []Cell,
};
