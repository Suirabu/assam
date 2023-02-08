const std = @import("std");

pub const Value = union(ValueTag) {
    const Self = @This();

    ptr: u64,
    int: u64,
    float: f64,
    bool: bool,

    pub fn format(self: Self, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = fmt;
        _ = options;

        switch (self) {
            Value.ptr => |value| try writer.print("{X}", .{value}),
            Value.int => |value| try writer.print("{d}", .{value}),
            Value.float => |value| try writer.print("{d}", .{value}),
            Value.bool => |value| try writer.print("{s}", .{if (value) "true" else "false"}),
        }
    }
};

pub const ValueTag = enum(u8) {
    ptr,

    int,

    float,
    bool,
};
