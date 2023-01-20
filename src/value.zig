const std = @import("std");

pub const Value = union(ValueTag) {
    BlockIndex: u32,
    Float: f64,
    Int: u64,
    Byte: u8,
    Bool: bool,

    pub fn eql(a: Value, b: Value) bool {
        const a_tag: ValueTag = a;
        const b_tag: ValueTag = b;
        if (a_tag != b_tag) {
            return false;
        }

        return switch (a) {
            .BlockIndex => a.BlockIndex == b.BlockIndex,
            .Float => a.Float == b.Float,
            .Int => a.Int == b.Int,
            .Byte => a.Byte == b.Byte,
            .Bool => a.Bool == b.Bool,
        };
    }

    pub fn format(value: Value, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = fmt;
        _ = options;

        switch (value) {
            Value.BlockIndex => |inner_value| try writer.print("{X}", .{inner_value}),
            Value.Float => |inner_value| try writer.print("{d}", .{inner_value}),
            Value.Int => |inner_value| try writer.print("{d}", .{inner_value}),
            Value.Byte => |inner_value| try writer.print("{X}", .{inner_value}),
            Value.Bool => |inner_value| try writer.print("{s}", .{if (inner_value) "true" else "false"}),
        }
    }
};

pub const ValueTag = enum(u8) {
    BlockIndex,
    Float,
    Int,
    Byte,
    Bool,
};
