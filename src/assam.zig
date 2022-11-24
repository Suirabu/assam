const vm = @import("vm.zig");
pub const VirtualMachine = vm.VirtualMachine;
pub const VirtualMachineError = vm.VirtualMachineError;

const instruction = @import("instruction.zig");
pub const Instruction = instruction.Instruction;
pub const InstructionTag = instruction.InstructionTag;
