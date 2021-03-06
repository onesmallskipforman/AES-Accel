# AES-Accel

AES-Accel is SystemVerilog hardware accelerator code to perform the AES Encryption and Decryption algorithms. Supports 128-, 192-, and 256- bit encryption and decryption. For further detail about the algorithm, please see [`doc/`](https://github.com/onesmallskipforman/AES-Accel/tree/master/doc).

## Purpose

AES encryption is a lengthy process for a single core. To relieve a CPU of this load, an FPGA can provide much-needed parallel computation for encryption. The repetitive nature of the AES key expansion and ciphering allows for feasible development of HDL code to parallelize this algorithm.

## Test and Simulation

Several tests were in simulation, using [`sim/testbench.sv`](https://github.com/onesmallskipforman/AES-Accel/tree/master/sim/testbench.sv) in modelsim, as well as in real-time, using [`test/testcoms.c`](https://github.com/onesmallskipforman/AES-Accel/tree/master/test/testcoms.c) from a rasberry pi.

### A Note about reading textfiles

Part of this project involves reading a textfile at compile time using the `$readmemh` call. Depending on where you place project files for synthesis and simulation, you may have to change the listed path of that textfile in that call.

## Related Work

### ToolBox

Several of these modules are generalized and could be used in other projects. I keep all of my multi-purpose SystemVerilog modules in another repo of mine, [SV-Toolbox](https://github.com/onesmallskipforman/SV-Toolbox).
