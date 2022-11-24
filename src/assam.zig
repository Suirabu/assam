const vm = @import("vm.zig");
pub const VirtualMachine = vm.VirtualMachine;
const VirtualMachineError = vm.VirtualMachineError;

const instruction = @import("instruction.zig");
pub const Instruction = instruction.Instruction;
pub const InstructionTag = instruction.InstructionTag;

const value = @import("value.zig");
pub const Value = value.Value;
pub const ValueTag = value.ValueTag;

pub const AssamError = VirtualMachineError;
