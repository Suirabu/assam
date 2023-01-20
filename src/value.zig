const std = @import("std");

pub const Value = union(ValueTag) {
    const Self = @This();

    BlockIndex: u32,
    Pointer: u32,

    Int64: u64,
    Int32: u32,
    Int16: u16,
    Int8: u8,

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
            .Int64 => a.Int64 == b.Int64,
            .Int32 => a.Int32 == b.Int32,
            .Int16 => a.Int16 == b.Int16,
            .Int8 => a.Int8 == b.Int8,
            .Bool => a.Bool == b.Bool,
        };
    }

    pub fn toBaseInt(self: Self) u64 {
        return switch (self) {
            Value.BlockIndex, Value.Pointer, Value.Int32 => |value| @intCast(u64, value),
            Value.Int64 => |value| value,
            Value.Int16 => |value| @intCast(u64, value),
            Value.Int8 => |value| @intCast(u64, value),
            Value.Float => |value| @floatToInt(u64, value),
            Value.Bool => |value| @boolToInt(value),
        };
    }

    /// Returns whether the underlying value is represented as an integer by the virtual machine
    pub fn isNativeInt(self: Self) bool {
        return switch (self) {
            Value.BlockIndex, Value.Pointer, Value.Int64, Value.Int32, Value.Int16, Value.Int8 => true,
            else => false,
        };
    }

    // Returns whether the value is an integer
    pub fn isInt(self: Self) bool {
        return switch (self) {
            Value.Int64, Value.Int32, Value.Int16, Value.Int8 => true,
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
        } else if (lhs == .Int64 or rhs == .Int64) {
            return .Int64;
        } else if (lhs == .Int32 or rhs == .Int32) {
            return .Int32;
        } else if (lhs == .Int16 or rhs == .Int16) {
            return .Int16;
        } else if (lhs == .Int8 or rhs == .Int8) {
            return .Int8;
        }

        unreachable;
    }

    pub fn format(self: Self, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = fmt;
        _ = options;

        switch (self) {
            Value.BlockIndex, Value.Pointer => |value| try writer.print("{X}", .{value}),
            Value.Int64, Value.Int32, Value.Int16, Value.Int8 => try writer.print("{d}", .{self.toBaseInt()}),
            Value.Float => |value| try writer.print("{d}", .{value}),
            Value.Bool => |value| try writer.print("{s}", .{if (value) "true" else "false"}),
        }
    }
};

pub const ValueTag = enum(u8) {
    BlockIndex,
    Pointer,

    Int64,
    Int32,
    Int16,
    Int8,

    Float,
    Bool,
};
