const std = @import("std");
const fmt = std.fmt;

pub const Value = union(ValueTag) {
    Int: u64,
    Bool: bool,

    pub fn eql(a: Value, b: Value) bool {
        const a_tag: ValueTag = a;
        const b_tag: ValueTag = b;
        if (a_tag != b_tag) {
            return false;
        }

        return switch (a) {
            .Int => a.Int == b.Int,
            .Bool => a.Bool == b.Bool,
        };
    }
};

pub const ValueTag = enum {
    Int,
    Bool,
};
