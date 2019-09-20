# InvAES-Accel

Inverse-AES is SystemVerilog hardware accelerator code to perform AES Decryption algorithm. Supports 128-, 192-, and 256- bit encryption. For further detail about the algorithm, please see `doc/`.

## Purpose

AES decryption is a lengthy process for a single core. To relieve a CPU of this load, an FPGA can provide much-needed parallel computation for the decryption process. The repetitive nature of the AES key expansion and ciphering allows for feasible development of HDL code to parallelize this algorithm.

## Upcoming features

I am currently working on extending the SystemVerilog to perform AES-192 and AES-256 decryption.

## Test and Simulation

Several tests were in simulation, using `sim/testbench.sv` in modelsim, as well as in real-time, using `test/testcoms.c` from a rasberry pi.

### A Note about reading textfiles

Part of this project involves reading a textfile at compile time using the `$readmemh` call. Depending on where you place project files for synthesis and simulation, you may have to change the listed path of that textfile in that call.

## Related Work

### AES Encryption

For every decryption there is an equal and opposite encryption! The systemverilog code for AES Encryption on a hardware accelerator can be found in my other repo, [AES-Accel](https://github.com/onesmallskipforman/AES-Accel).

### ToolBox

Several of these modules are generalized and could be used in other projects. I keep all of my multi-purpose SystemVerilog modules in another repo of mine, [SV-Toolbox](https://github.com/onesmallskipforman/SV-Toolbox).