pub const Cell = u64;

// Public imports

const vm = @import("vm.zig");
pub const VirtualMachine = vm.VirtualMachine;
pub const VirtualMachineError = vm.VirtualMachineError;

const instruction = @import("instruction.zig");
pub const Instruction = instruction.Instruction;
pub const InstructionTag = instruction.InstructionTag; // Not sure if the tag is useful here...

const bytecode = @import("bytecode.zig");
pub const BytecodeModule = bytecode.BytecodeModule;
