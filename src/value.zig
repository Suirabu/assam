const std = @import("std");

pub const Value = union(ValueTag) {
    const Self = @This();

    BlockIndex: u32,
    Pointer: u32,
    Int: u64,
    Float: f64,
    Bool: bool,

    pub fn eql(a: Value, b: Value) bool {
        const a_tag: ValueTag = a;
        const b_tag: ValueTag = b;
        if (a_tag != b_tag) {
            return false;
        }

        return switch (a) {
            .BlockIndex => a.BlockIndex == b.BlockIndex,
            .Pointer => a.Pointer == b.Pointer,
            .Float => a.Float == b.Float,
            .Int => a.Int == b.Int,
            .Bool => a.Bool == b.Bool,
        };
    }

    pub fn toInt(self: Self) u64 {
        return switch (self) {
            Value.BlockIndex, Value.Pointer => |value| @intCast(u64, value),
            Value.Int => |value| value,
            Value.Float => |value| @floatToInt(u64, value),
            Value.Bool => |value| @boolToInt(value),
        };
    }

    /// Returns whether the underlying value is represented as an integer by the virtual machine
    pub fn isNativeInt(self: Self) bool {
        return switch (self) {
            Value.BlockIndex, Value.Pointer, Value.Int => true,
            else => false,
        };
    }

    // Returns whether the value is an integer
    pub fn isInt(self: Self) bool {
        return switch (self) {
            Value.Int => true,
            else => false,
        };
    }

    // Returns the highest priority of two integer types
    pub fn getPriorityIntTag(lhs: Self, rhs: Self) !ValueTag {
        if (!lhs.isNativeInt() or !rhs.isNativeInt()) {
            return error.TypeError;
        }

        if (lhs == .BlockIndex or rhs == .BlockIndex) {
            return .BlockIndex;
        } else if (lhs == .Pointer or rhs == .Pointer) {
            return .Pointer;
        } else if (lhs == .Int or rhs == .Int) {
            return .Int;
        }

        unreachable;
    }

    pub fn format(self: Self, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = fmt;
        _ = options;

        switch (self) {
            Value.BlockIndex, Value.Pointer => |value| try writer.print("{X}", .{value}),
            Value.Int => try writer.print("{d}", .{self.toInt()}),
            Value.Float => |value| try writer.print("{d}", .{value}),
            Value.Bool => |value| try writer.print("{s}", .{if (value) "true" else "false"}),
        }
    }
};

pub const ValueTag = enum(u8) {
    BlockIndex,
    Pointer,

    Int,

    Float,
    Bool,
};
