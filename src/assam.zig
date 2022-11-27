const vm = @import("vm.zig");
pub const VirtualMachine = vm.VirtualMachine;
const VirtualMachineError = vm.VirtualMachineError;

const instruction = @import("instruction.zig");
pub const Instruction = instruction.Instruction;
pub const InstructionTag = instruction.InstructionTag;

const value = @import("value.zig");
pub const Value = value.Value;
pub const ValueTag = value.ValueTag;

const bytecode = @import("bytecode.zig");
pub const BytecodeModule = bytecode.BytecodeModule;

pub const AssamError = VirtualMachineError;
