const vm = @import("vm.zig");
pub const VirtualMachine = vm.VirtualMachine;
const VirtualMachineError = vm.VirtualMachineError;

const instruction = @import("instruction.zig");
pub const Instruction = instruction.Instruction;
pub const InstructionTag = instruction.InstructionTag;

pub const AssamError = VirtualMachineError;
