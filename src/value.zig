const std = @import("std");

pub const Value = union(ValueTag) {
    const Self = @This();

    block_index: u32,
    pointer: u32,
    int: u64,
    float: f64,
    bool: bool,

    pub fn eql(a: Value, b: Value) bool {
        const a_tag: ValueTag = a;
        const b_tag: ValueTag = b;
        if (a_tag != b_tag) {
            return false;
        }

        return switch (a) {
            .block_index => a.block_index == b.block_index,
            .pointer => a.pointer == b.pointer,
            .float => a.float == b.float,
            .int => a.int == b.int,
            .bool => a.bool == b.bool,
        };
    }

    pub fn toInt(self: Self) u64 {
        return switch (self) {
            Value.block_index, Value.pointer => |value| @intCast(u64, value),
            Value.int => |value| value,
            Value.float => |value| @floatToInt(u64, value),
            Value.bool => |value| @boolToInt(value),
        };
    }

    /// Returns whether the underlying value is represented as an integer by the virtual machine
    pub fn isNativeInt(self: Self) bool {
        return switch (self) {
            Value.block_index, Value.pointer, Value.int => true,
            else => false,
        };
    }

    // Returns whether the value is an integer
    pub fn isInt(self: Self) bool {
        return switch (self) {
            Value.int => true,
            else => false,
        };
    }

    // Returns the highest priority of two integer types
    pub fn getPriorityIntTag(lhs: Self, rhs: Self) !ValueTag {
        if (!lhs.isNativeInt() or !rhs.isNativeInt()) {
            return error.TypeError;
        }

        if (lhs == .block_index or rhs == .block_index) {
            return .block_index;
        } else if (lhs == .pointer or rhs == .pointer) {
            return .pointer;
        } else if (lhs == .int or rhs == .int) {
            return .int;
        }

        unreachable;
    }

    pub fn format(self: Self, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = fmt;
        _ = options;

        switch (self) {
            Value.block_index, Value.pointer => |value| try writer.print("{X}", .{value}),
            Value.int => try writer.print("{d}", .{self.toInt()}),
            Value.float => |value| try writer.print("{d}", .{value}),
            Value.bool => |value| try writer.print("{s}", .{if (value) "true" else "false"}),
        }
    }
};

pub const ValueTag = enum(u8) {
    block_index,
    pointer,

    int,

    float,
    bool,
};
