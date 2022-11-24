# Assam

Assam aims to be a simple yet powerful compilation target for high-level programming languages.

Assam provides a public interface for generating Assam bytecode modules which can then be run on the Assam virtual
machine (AVM). This virtual machine can either be embedded directly into your Zig project using the aforementioned
public interface, or it can be built from source and run as a standalone executable.

I eventually hope to expand the scope of this project to include features such as an OS-independent system interface,
code optimization, and native code generation. These features, however, will not be implemented until the design of the
AVM has been more or less stabilized.

This project is still in its infancy and bugs are to be expected. If you encounter a bug please open a new issue
describing your problem.

## Get Started

### Compile the Assam Virtual Machine

You will need the most recent stable release of the [Zig compiler](https://ziglang.org/download/)
(currently version 0.10.0) to compile the AVM from source.

I recommend compiling the AVM using the following command:

```
zig build -Drelease-safe
```

The resulting binary can then be located at `./zig-out/bin/avm`.
