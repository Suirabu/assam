const std = @import("std");
const fmt = std.fmt;

pub const Value = union(ValueTag) {
    BlockIndex: u32,
    Int: u64,
    Bool: bool,

    pub fn eql(a: Value, b: Value) bool {
        const a_tag: ValueTag = a;
        const b_tag: ValueTag = b;
        if (a_tag != b_tag) {
            return false;
        }

        return switch (a) {
            .BlockIndex => a.BlockIndex == b.BlockIndex,
            .Int => a.Int == b.Int,
            .Bool => a.Bool == b.Bool,
        };
    }
};

pub const ValueTag = enum(u8) {
    BlockIndex,
    Int,
    Bool,
};
