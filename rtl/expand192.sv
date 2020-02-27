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

module expand192 (input  logic          clk, reset,
                  input  logic          done,
                  input  logic [191:0]  key,
                  output logic [127:0]  roundKey);

  logic [191:0] block, nextBlock;
  logic [127:0] temp, replace;
  logic [31:0]  rcon, nextrcon, rotTemp, transform, subTemp, rconTemp;
  logic [7:0]   rconFront, invrconFront;

  typedef enum logic [1:0] {S0, S1, S2} statetype;
  statetype state, nextstate;

  always_ff @(posedge clk) begin
    if (reset) begin
      state    <= S0;
      block    <= key;
      rcon     <= 32'h8d000000;
    end else if (!done) begin
      state    <= nextstate;
      block    <= nextBlock;
      rcon     <= nextrcon;
    end
  end

  // next state logic
  always_comb
    case (state)
      S0: nextstate = S1;
      S1: nextstate = S2;
      S2: nextstate = S0;
      default: nextstate = S0;
    endcase

  // next round constant (rcon for current temp transform) logic
  galoismult    gm(rcon[31:24], rconFront);
  invgaloismult ig(rcon[31:24], invrconFront);
  assign nextrcon  = (state == S2)? rcon        : {rconFront, 24'b0};

  assign transform = (state == S0)? block[31:0] : temp[95:64];
  rotate #(1, 4, 8) rw(transform, rotTemp);
  subword sw(rotTemp, subTemp);
  assign rconTemp = subTemp^nextrcon;

  always_comb begin
    replace = block[191:64];
    temp[127:96] = (state == S0)? replace[127:96] ^ rconTemp : replace[127:96] ^ block[31:0];
    temp[95:64]  =                                             replace[95:64]  ^ temp[127:96];
    temp[63:32]  = (state == S1)? replace[63:32]  ^ rconTemp : replace[63:32]  ^ temp[95:64];
    temp[31:0]   =                                             replace[31:0]   ^ temp[63:32];
  end

  assign nextBlock = {block[63:0], temp};
  assign roundKey  = replace;

endmodule
