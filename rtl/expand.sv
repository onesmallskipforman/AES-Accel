/*
  Robert "Skipper" Gonzalez
  sgonzalez@g.hmc.edu
  12/10/2019
  AES 128-bit key expansion

  Below is a module that performs the keyexpansion function for K-bit AES
  encryption. This module runs 4 steps of the algorithm at a time,
  allowing 128-, 192-, and 128-bit encyption encryption to complete
  11 cycles, 13 cycles, and 15 cycles, respectively.

  Parameters:
    K:                        the length of the key

  Inputs:
    clk:              sytem clock signal
    reset:            reset signal to restart cypher process
    done:             done/disable bit signalling encryption completed
    key[K-1:0]:       K-bit encryption key

  Outputs:
    roundKey[127:0]:    block of four words generated in current cycle of key expansion

  Internal Variables:
    wBlock[127:0]:    block of K words generated for the expanded key
    rcon[31:0]:       round constant word array for the first step of the current cycle
    rotTemp[31:0]:    rotWord transform applied to last cylce's wBlock
    subTemp[31:0]:    subWord transform applied to rotTemp
    subOrgTemp[31:0]: subWord transform applied to last cylce's wBlock
    finalTemp[31:0]:  final temp value to be XOR'ed with lastBlock[127:96]
    rconTemp[31:0]:   XOR between subWord and rcon
    lastBlock[127:0]: last word from the expansion block from the last cycle
    temp[127:0]:      temporary storage for wBlock for cycles 2-10
    rconFront[7:0]:   First word in rcon
*/

module expand #(parameter K = 128, INV = 0)
               (input  logic         clk, reset,
                input  logic         done1, done2, predone,
                input  logic [K-1:0] key,
                output logic [127:0] roundKey);

  generate
    if (INV == 0) begin
      if (K == 128) expand128 e128(clk, reset, done1, key, roundKey);
      if (K == 192) expand192 e192(clk, reset, done1, key, roundKey);
      if (K == 256) expand256 e256(clk, reset, done1, key, roundKey);
    end else begin
      if (K == 128) iexpand128 ie128(clk, reset, done1, done2, key, roundKey);
      if (K == 192) iexpand192 ie192(clk, reset, done1, done2, predone, key, roundKey);
      if (K == 256) iexpand256 ie256(clk, reset, done1, done2, predone, key, roundKey);
    end
  endgenerate

  // logic [127:0] roundKey;
  // logic wasdone;
  // parameter NR = (K == 128)? 10 : (K == 192)? 12 : 14;
  // parameter WIDTH = NR*128;
  // logic [WIDTH-1:0] bigroundkey;

  // always_ff @(posedge clk) begin
  //   wasdone <= done1;
  //   // if      (reset)    bigroundkey <= {WIDTH{1'b0}};
  //   if (!wasdone) bigroundkey <= {roundKey, bigroundkey[WIDTH-1:128]};
  //   // else          bigroundkey <= bigroundkey << 128;
  //   // else          bigroundkey <= {bigroundkey[(NR-1)*128 - 1 : 0], bigroundkey[WIDTH-1:(NR-1)*128]};
  //   // else          bigroundkey <= {bigroundkey[128: 0], bigroundkey[WIDTH-1:128]};
  // end
  // assign outroundKey = (!wasdone)? roundKey : bigroundkey[WIDTH-1:(NR-1)*128];
endmodule
