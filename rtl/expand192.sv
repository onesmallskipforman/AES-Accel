/*
  Robert "Skipper" Gonzalez
  sgonzalez@g.hmc.edu
  12/10/2019
  AES 192-bit key expansion

  Below is a module that performs the key expansion function for 192-bit AES
  encryption. This module runs 4 steps of the algorithm at a time,
  allowing 192-bit encyption to complete in 13 cycles.

  Inputs:
    clk:        sytem clock signal
    reset:      reset signal to restart cypher process
    done:       bit signalling encryption complete
    key[191:0]: 192-bit encryption key

  Outputs:
    roundKey[127:0]: 4-word round key generated in current cycle of expansion

  Internal Variables:
    block[191:0]:      block of 6 words generated for the expanded key
    nextBlock[191:0]:  next block of 6 words generated for the expanded key
    temp[127:0]:       next 4 words generated for the block
    replace[127:0]:    4 words from block to be transformed and replaced by temp
    rcon[31:0]:        round constant word array
    nextrcon[31:0]:    next round constant word array
    rotTemp[31:0]:     rotWord transform applied to block
    subTemp[31:0]:     subWord transform applied to rotTemp
    transform[31:0]:   4 words to be rotated into rotTemp
    rconTemp[31:0]:    XOR between subWord and rcon
    rconFront[7:0]:    First word in rcon after galois mult to nextrcon
    invrconFront[7:0]: First word in rcon after inverse galois mult to nextrcon
*/

module expand192 (input  logic          clk, reset,
                  input  logic          done,
                  input  logic [191:0]  key,
                  output logic [127:0]  roundKey);

  logic [191:0] block, nextBlock;
  logic [127:0] temp, replace;
  logic [31:0]  rcon, nextrcon, rotTemp, subTemp, rconTemp, transform;
  logic [7:0]   rconFront;

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
