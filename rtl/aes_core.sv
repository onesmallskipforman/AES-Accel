/*
  Robert "Skipper" Gonzalez
  sgonzalez@g.hmc.edu
  12/10/2019
  AES encryption module

  Below is a module that performs various forms of AES encryption and
  decryption. Wheh load is asserted and then deasserted, the module takes the
  current 128-, 192-, or 128-bit key and 128-bit message to generate a
  translation over 11 cycles, 13 cycles, and 15 cycles, respectively. After the
  cycles are complete, the module asserts done. Instantiations that support
  encryption only, decryption only, and both, are supported, and are configured
  with INV.

  Visualization of message, roundKey, state, and translated Storage:
    The key and message are 128-bit values packed into an array of 16 bytes as shown below
      [127:120] [95:88] [63:56] [31:24]     S0,0    S0,1    S0,2    S0,3
      [119:112] [87:80] [55:48] [23:16]     S1,0    S1,1    S1,2    S1,3
      [111:104] [79:72] [47:40] [15:8]      S2,0    S2,1    S2,2    S2,3
      [103:96]  [71:64] [39:32] [7:0]       S3,0    S3,1    S3,2    S3,3

    Equivalently, the values are packed into four words as given
      [127:96]  [95:64] [63:32] [31:0]      w[0]    w[1]    w[2]    w[3]

  Parameters:
    K:           the length of the key
    INV:         encryption type (0: encryption, 1: decryption, 2: both)
    CYCLES[3:0]: number of cycles for algorithm
    C:           size of the counter in bits

  Inputs:
    clk:            sytem clock signal
    ce:             pi chip enable. high when new message should be translated
    key[K-1:0]:     K-bit encryption key
    message[127:0]: unecrpyted 128-bit message
    asyncdir:       direction signal, changes during any spi

  Outputs:
    done2:             bit signalling algorithm complete
    translated[127:0]: encrypted 128-bit message

  Internal Variables:
    roundKey[127:0]: block of 4 words generated in a cycle of key expansion
    countval[3:0]:   current cycle
    done1:           bit signalling forward key expansion complete
    predon:          bit signalling forward key one clk tick from complete
    dir:             direction signal, changes with ce
*/

module aes_core #(parameter K = 128, INV = 1)
                 (input  logic         clk,
                  input  logic         ce,
                  input  logic [K-1:0] key,
                  input  logic [127:0] message,
                  input  logic         asyncdir,          // 0 is fwd
                  output logic         done2,
                  output logic [127:0] translated);

  parameter logic [3:0] CYCLES = (K == 128)? 4'b1011 : (K == 192)? 4'b1101 : 4'b1111;
  parameter C = (INV == 0)? 4 : 5;
  logic [127:0] roundKey;
  logic [C-1:0] countval;
  logic         done1, predone, dir;

  // only change dir when resetting translation with ce
  // (not needed when spi conditionally synchronized)
  always_ff @(posedge clk) if (ce) dir <= asyncdir;

  // counter for cipher and expansion step
  counter #(C) cnt(clk, ce, !done2, 1'b1, countval);

  // send cipher a 4-word key schedule to transform message each cycle
  expand  #(K, INV) ke0(clk, ce, done1, done2, predone, key, roundKey);

  // ciphering
  generate
    if (INV == 0) cipher    ci0(clk, ce, done1, roundKey, message, translated);
    if (INV == 1) invcipher in0(clk, (countval <= CYCLES-1'b1), done2, roundKey, message, translated);
    if (INV == 2) ocipher   oc0(clk, ce | (dir & (countval <= CYCLES-1'b1)), done2, dir, roundKey, message, translated);
  endgenerate

  // done signals based on counter
  always_comb begin
    predone = (countval == CYCLES - 2'b10);
    done1   = (countval >= CYCLES - 1'b1);
    if (INV == 0) done2 = done1;
    if (INV == 1) done2 = (countval == 2*(CYCLES - 1'b1));
    if (INV == 2) done2 = (!dir)? done1 : (countval == 2*(CYCLES-1'b1));
  end
endmodule

// generate 5 MHz clock for cycles
// clk_gen #(5 * (10**6)) sck(clk, ce, 1'b1, slwclk);
// (!dir)? ce : (countval <= CYCLES-1'b1)
