/*
  Robert "Skipper" Gonzalez
  sgonzalez@g.hmc.edu
  12/10/2019
  AES 256-bit key expansion and reverse expansion

  Below is a module that performs the key expansion, and then reverse expansion,
  function for 256-bit AES. This module runs 4 steps of the algorithm at a time,
  allowing 256-bit encryption to complete in 15 cycles, and decryption in 30.

  Inputs:
    clk:        sytem clock signal
    reset:      reset signal to restart cypher process
    done1:      bit signalling expansion complete
    done2:      bit signalling reverse expansion complete
    key[255:0]: 256-bit encryption key

  Outputs:
    roundKey[127:0]: 4-word round key generated in current cycle of expansion

  Internal Variables:
    block[255:0]:      block of 8 words generated for the expanded key
    nextBlock[255:0]:  next block of 8 words generated for the expanded key
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
    tosub[31:0]:       4 words to be substituted into subTemp
    wasdone1:          signals if done1 was high on last clock tick
    pivot:             signals if done1 high and wasdone1 low
*/

module iexpand256 (input  logic          clk, reset,
                   input  logic          done1,
                   input  logic          done2, predone,
                   input  logic [255:0]  key,
                   output logic [127:0]  roundKey);

  logic [31:0]  rcon, nextrcon, rotTemp, subTemp, rconTemp, tosub;
  logic [255:0] block, nextBlock;
  logic [127:0] temp, replace;
  logic [7:0]   rconFront, invrconFront;
  logic         wasdone1, pivot;

  typedef enum logic {S0, S1} statetype;
  statetype state, nextstate;

  always_ff @(posedge clk)
    if (reset) begin
      state       <= S0;
      block       <= key;
      rcon        <= 32'h8d000000;
      wasdone1    <= 1'b0;
    end else if (!done2) begin
      state       <= nextstate;
      block       <= nextBlock;
      rcon        <= nextrcon;
      wasdone1    <= done1;
    end

  assign pivot = (done1 & !wasdone1);

  // next state logic
  always_comb
    case (state)
      S0:      nextstate = S1;
      S1:      nextstate = S0;
      default: nextstate = S0;
    endcase

  // next round constant (rcon for current temp transform) logic
  galoismult    gm(rcon[31:24], rconFront);
  invgaloismult ig(rcon[31:24], invrconFront);

  always_comb
    if      (pivot | state != S0) nextrcon = rcon;
    else if (done1) nextrcon = {invrconFront, 24'b0};
    else            nextrcon = {rconFront, 24'b0};

  // temp block logic
  rotate #(1, 4, 8) rw(block[31:0], rotTemp);
  assign tosub = (state == S0)? rotTemp : block[31:0];
  subword sw(tosub, subTemp);

  assign rconTemp = subTemp ^ nextrcon;
  assign replace = (state == S0)? block[255:128] : block[127:0];

  always_comb begin
    temp[127:96] = (state == S0)? (block[255:224] ^ rconTemp) : (block[255:224] ^ subTemp);
    if (done1) begin temp[95:0] = block[223:128] ^ block[255:160]; end
    else begin
      temp[95:64] = (block[223:192] ^ temp[127:96]);
      temp[63:32] = (block[191:160] ^ temp[95:64]);
      temp[31:0]  = (block[159:128] ^ temp[63:32]);
    end
  end

  // next expansion block and output logic
  assign nextBlock = (predone)? {block[127:0], block[255:128]} : {block[127:0], temp};
  assign roundKey  = block[255: 128];

endmodule
