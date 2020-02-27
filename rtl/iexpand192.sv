/*
  Robert "Skipper" Gonzalez
  sgonzalez@g.hmc.edu
  12/10/2019
  AES 192-bit key expansion and reverse expansion

  Below is a module that performs the key expansion, and then reverse expansion,
  function for 192-bit AES. This module runs 4 steps of the algorithm at a time,
  allowing 192-bit encryption to complete in 11 cycles, and decryption in 22.

  Inputs:
    clk:        sytem clock signal
    reset:      reset signal to restart cypher process
    done1:      bit signalling expansion complete
    done2:      bit signalling reverse expansion complete
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
    wasdone1:          signals if done1 was high on last clock tick
*/

module iexpand192 (input  logic          clk, reset,
                   input  logic          done1,
                   input  logic          done2, predone,
                   input  logic [191:0]  key,
                   output logic [127:0]  roundKey);

  logic [191:0] block, nextBlock;
  logic [127:0] temp, replace;
  logic [31:0]  rcon, nextrcon, rotTemp, transform, subTemp, rconTemp;
  logic [7:0]   rconFront, invrconFront;
  logic         wasdone1;

  typedef enum logic [1:0] {S0, S1, S2} statetype;
  statetype state, nextstate;

  always_ff @(posedge clk) begin
    if (reset) begin
      state    <= S0;
      block    <= key;
      rcon     <= 32'h8d000000;
      wasdone1 <= 1'b0;
    end else if (!done2) begin
      state    <= nextstate;
      block    <= nextBlock;
      rcon     <= nextrcon;
      wasdone1 <= done1;
    end
  end

  // next state logic
  always_comb
    case (state)
      S0: nextstate = (!done1)? S1 : S2;
      S1: nextstate = (!done1)? S2 : S0;
      S2: nextstate = (!done1)? S0 : S1;
      default: nextstate = S0;
    endcase

  // next round constant (rcon for current temp transform) logic
  galoismult    gm(rcon[31:24], rconFront);
  invgaloismult ig(rcon[31:24], invrconFront);

  always_comb
    if      ((done1 & !wasdone1) | state == S2) nextrcon = rcon;
    else if (done1)                             nextrcon = {invrconFront, 24'b0};
    else                                        nextrcon = {rconFront, 24'b0};

  always_comb
    if (!done1) transform = (state == S0)? block[31:0]    : temp[95:64];
    else        transform = (state == S0)? block[159:128] : block[95:64];

  rotate #(1, 4, 8) rw(transform, rotTemp);
  subword sw(rotTemp, subTemp);

  assign rconTemp = subTemp^nextrcon;

  assign replace = (!done1)? block[191:64] : block[127:0];
  always_comb begin
    temp[127:96] = (state == S0)? replace[127:96] ^ rconTemp : (!done1)? replace[127:96] ^ block[31:0]  : replace[127:96] ^ block[159:128];
    temp[95:64]  =                                             (!done1)? replace[95:64]  ^ temp[127:96] : replace[95:64]  ^ replace[127:96];
    temp[63:32]  = (state == S1)? replace[63:32]  ^ rconTemp : (!done1)? replace[63:32]  ^ temp[95:64]  : replace[63:32]  ^ replace[95:64];
    temp[31:0]   =                                             (!done1)? replace[31:0]   ^ temp[63:32]  : replace[31:0]   ^ replace[63:32];
  end

  assign nextBlock = (predone)? {block[127:0], temp[127:64]} : (!done1)? {block[63:0], temp} : {temp, block[191:128]};
  assign roundKey  = replace;

endmodule
