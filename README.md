# AES-Accel

AES-Accel is SystemVerilog hardware accelerator code to perform the AES Encryption algorithm. Currently only supports 128-bit encryption.

## Purpose

AES encryption is a lengthy process for a single core. To relieve a CPU of this load, an FPGA can provide much-needed parallel computation for encryption. The repetitive nature of the AES key expansion and ciphering allows for feasible development of HDL code to parallelize this algorithm.

## Upcoming features

I am currently working on extending the SystemVerilog to perform AES-192 and AES-256 encryption, as well as decrytion for all three AES standards.

## Related Work

Several of these modules are generalized and could be used in othe projects. I keep all of my multi-purpose SystemVerilog modules in my other git repo, [SV-Toolbox](https://github.com/onesmallskipforman/SV-Toolbox).