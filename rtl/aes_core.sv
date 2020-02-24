/*
  Robert "Skipper" Gonzalez
  sgonzalez@g.hmc.edu
  12/10/2019
  AES encryption module

  Below is a module that performs AES encryption. Wheh load is asserted
  and then deasserted, the module takes the current 128-, 192-, or 128-bit key
  and 128-bit plaintext to generate cyphertext over 11 cycles, 13 cycles, and 15 cycles,
  respectively. After the cycles are complete, the module asserts done.

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
    key[K-1:0]:        K-bit encryption key
    plaintext[127:0]:  unecrpyted 128-bit message

  Outputs:
    done:              done bit signalling encryption completed
    cyphertext[127:0]: encrypted 128-bit message

  Internal Variables:
    roundKey[127:0]:   block of Nk=4 words generated in a cycle of key expansion
    countval[3:0]:     current cycle
    slwclk:            4 MHz slower clock signal driving the cycle
*/

module aes_core #(parameter K = 128)
                 (input  logic         clk, reset,
                  input  logic         ce,
                  input  logic [K-1:0] key,
                  input  logic [127:0] message,
                  // input  logic         dir,          // 0 is fwd
                  output logic         done2,
                  output logic [127:0] translated);

  logic [127:0] roundKey; //, encrypted, decrypted;
  logic [4:0]   countval;
  logic         slwclk, done1;
  logic predone;


  // generate 5 MHz clock for cycles
  // clk_gen #(5 * (10**6)) sck(clk, reset, 1'b1, slwclk);

  // counter for cipher and expansion steps
  counter #(5) cnt(clk, ce, !done2, 1'b1, countval);

  // send key a 4-word key schedule to cipher each cycle
  expand  #(K) ke0(clk, ce, done1, done2, predone, key, roundKey);
  // cipher       ci0(clk, ce, done1, roundKey, message, translated);
  // assign translated = (dir)? decrypted : encrypted;

  parameter logic [3:0] cycles = (K == 128)? 5'b1011 : (K == 192)? 5'b1101 : 5'b1111;

  // ocipher      ci0(clk, ce | (dir & (countval == cycles-1'b1)), done2, dir, roundKey, message, translated);
  invcipher    in0(clk, ce | (countval == cycles-1'b1), done2, roundKey, message, translated);


  assign done1 = (countval >= cycles - 1'b1);
  // assign done2 = (dir)? (countval == 2*cycles) : done1;
  // assign done2 = done1;
  assign done2 = (countval == 2*(cycles - 1'b1));
  assign predone = (countval == cycles - 2'b10);

endmodule
