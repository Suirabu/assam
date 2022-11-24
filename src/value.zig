const std = @import("std");
const fmt = std.fmt;

pub const Value = union(ValueTag) {
    Int: u64,
    Bool: bool,
};

pub const ValueTag = enum {
    Int,
    Bool,
};
