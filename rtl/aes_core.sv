/*
  Robert "Skipper" Gonzalez
  sgonzalez@g.hmc.edu
  12/10/2019
  AES encryption module

  Below is a module that performs 128-bit AES encryption. Wheh load is asserted
  and then deasserted, the module takes the current key and plaintext to generate
  cyphertext over 11 cycles. After the 11 cycles are complete, the module asserts done.

  Visualization of input, wBlock, and key Schedule Storage:
    The key and message are 128-bit values packed into an array of 16 bytes as shown below
         [127:120] [95:88] [63:56] [31:24]     S0,0    S0,1    S0,2    S0,3
         [119:112] [87:80] [55:48] [23:16]     S1,0    S1,1    S1,2    S1,3
         [111:104] [79:72] [47:40] [15:8]      S2,0    S2,1    S2,2    S2,3
         [103:96]  [71:64] [39:32] [7:0]       S3,0    S3,1    S3,2    S3,3

    Equivalently, the values are packed into four words as given
         [127:96]  [95:64] [63:32] [31:0]      w[0]    w[1]    w[2]    w[3]

  Inputs:
    clk:               sytem clock signal
    ce:                pi chip enable (or load). high during conversion
    key[127:0]:        128-bit encryption key
    plaintext[127:0]:  unecrpyted 128-bit message

  Outputs:
    done:              done bit signalling encryption completed
    cyphertext[127:0]: encrypted 128-bit message

  Internal Variables:
    wBlock[127:0]:     block of Nk=4 words generated in a cycle of key expansion
    countval[3:0]:     current cycle
    slwclk:            4 MHz slower clock signal driving the cycle
*/

module aes_core(input  logic         clk, reset,
                input  logic         ce,
                input  logic [127:0] key,
                input  logic [127:0] plaintext,
                output logic         done,
                output logic [127:0] cyphertext);

  logic [127:0] wBlock;
  logic [3:0]   countval;
  logic         slwclk;

  // generate 5 MHz clock for cycles
  clk_gen #(5 * (10**6)) sck(clk, reset, 1'b1, slwclk);
  counter #(4)           cnt(slwclk, ce, !done, 1'b1, countval);

  // send key a 4-word key schedule to cipher each cycle
  keyexpansion  ke0(slwclk, ce, done, key, wBlock);
  cipher        ci0(slwclk, ce, done, wBlock, plaintext, cyphertext);

  // the first cycle is the slwclk cycle after ce is deasserted,
  // meaning countval only has to count to 10
  assign done = (countval == 4'b1010);

endmodule
