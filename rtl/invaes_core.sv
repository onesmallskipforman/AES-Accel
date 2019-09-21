/*
  Robert "Skipper" Gonzalez
  sgonzalez@g.hmc.edu
  12/10/2019
  AES encryption module

  Below is a module that performs AES inverse encryption. When load is asserted
  and then deasserted, the module expands an input key to generate the last round key value over
  11 cycles. The module then uses this final round key value to perform inverse key expansion and
  inverse ciphering in order to decrypte the input cyphertext over an additional 11 cycles. After
  the 11 cycles are complete, the module asserts done.

  Visualization of plaintext, roundKey, state, and cyphertext Storage:
    The key and message are 128-bit values packed into an array of 16 bytes as shown below
         [127:120] [95:88] [63:56] [31:24]     S0,0    S0,1    S0,2    S0,3
         [119:112] [87:80] [55:48] [23:16]     S1,0    S1,1    S1,2    S1,3
         [111:104] [79:72] [47:40] [15:8]      S2,0    S2,1    S2,2    S2,3
         [103:96]  [71:64] [39:32] [7:0]       S3,0    S3,1    S3,2    S3,3

    Equivalently, the values are packed into four words as given
         [127:96]  [95:64] [63:32] [31:0]      w[0]    w[1]    w[2]    w[3]

  Parameters:
    K:                        the length of the key

  Inputs:
    clk:               sytem clock signal
    ce:                pi chip enable (or load). high during conversion
    key[K-1:0]:        128-bit encryption key
    plaintext[127:0]:  unecrpyted 128-bit message

  Outputs:
    done:              done bit signalling encryption completed
    cyphertext[127:0]: encrypted 128-bit message

  Internal Variables:
    roundKey[127:0]:     block of Nk=4 words generated in a cycle of key expansion
    countval1[3:0]:      current forward key expansion cycle
    countval2[3:0]:      current cycle of inverse expansion and encryption
    cycles[3:0]:         number of cycles needed to complete decryption
    slwclk:              4 MHz slower clock signal driving the cycle
    predone:             bit signalling forward key expansion is complete
*/

module invaes_core #(parameter K = 128)
                    (input  logic         clk, reset,
                    input  logic         ce,
                    input  logic [K-1:0] key,
                    input  logic [127:0] cyphertext,
                    output logic         done,
                    output logic [127:0] plaintext);

  logic [127:0] roundKey;
  logic [3:0]   countval1, countval2, cycles;
  logic         slwclk;
  logic         predone;

  // generate 5 MHz clock for cycles
  clk_gen #(5 * (10**6)) sck(clk, reset, 1'b1, slwclk);

  // counters for forward and reverse expansion
  counter #(4)  ct0(slwclk, ce, !predone, 1'b1, countval1);
  counter #(4)  ct1(slwclk, ce | !predone, !done, 1'b1, countval2);

  // send key a 4-word key schedule to cipher each cycle
  expand  #(K)  ex0(slwclk, ce, predone, done, key, roundKey);
  invcipher     ci0(slwclk, ce | !predone, done, roundKey, cyphertext, plaintext);

  generate
    if (K == 128) begin assign cycles = 4'b1011; end
    if (K == 192) begin assign cycles = 4'b1101; end
    if (K == 256) begin assign cycles = 4'b1111; end
  endgenerate

  assign predone = (countval1 == cycles);
  assign done    = (countval2 == (cycles-1'b1));

endmodule
