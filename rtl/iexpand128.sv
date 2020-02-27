/*
  Robert "Skipper" Gonzalez
  sgonzalez@g.hmc.edu
  12/10/2019
  AES 128-bit key expansion and reverse expansion

  Below is a module that performs the key expansion, and then reverse expansion,
  function for 128-bit AES. This module runs 4 steps of the algorithm at a time,
  allowing 128-bit encryption to complete in 13 cycles, and decryption in 26.

  Inputs:
    clk:        sytem clock signal
    reset:      reset signal to restart cypher process
    done1:      bit signalling expansion complete
    done2:      bit signalling reverse expansion complete
    key[127:0]: 128-bit encryption key

  Outputs:
    roundKey[127:0]: 4-word round key generated in current cycle of expansion

  Internal Variables:
    block[127:0]:      block of 4 words generated for the expanded key
    nextBlock[127:0]:  next block of 4 words generated for the expanded key
    rcon[31:0]:        round constant word array
    nextrcon[31:0]:    next round constant word array
    transform[31:0]:   4 words to be rotated into rotTemp
    temp[127:0]:       next 4 words generated for the block
    rotTemp[31:0]:     rotWord transform applied to block
    subTemp[31:0]:     subWord transform applied to rotTemp
    rconTemp[31:0]:    XOR between subWord and rcon
    rconfront[7:0]:    First word in rcon after galois mult to nextrcon
    invrconFront[7:0]: First word in rcon after inverse galois mult to nextrcon
    wasdone1:          signals if done1 was high on last clock tick
    pivot:             signals if done1 high and wasdone1 low
*/

module iexpand128 (input  logic          clk, reset,
                   input  logic          done1,
                   input  logic          done2,
                   input  logic [127:0]  key,
                   output logic [127:0]  roundKey);

  logic [31:0]  rcon, nextrcon, transform, rotTemp, subTemp, rconTemp;
  logic [127:0] block, temp, nextBlock;
  logic [7:0]   rconFront, invrconFront;
  logic         wasdone1, pivot;

  always_ff @(posedge clk)
    if (reset) begin
      block       <= key;
      rcon        <= 32'h8d000000;
      wasdone1    <= 1'b0;
    end else if (!done2) begin
      block       <= nextBlock;
      rcon        <= nextrcon;
      wasdone1    <= done1;
    end

  assign pivot = (done1 & !wasdone1);

  // next round constant (rcon for current temp transform) logic
  galoismult    gm(rcon[31:24], rconFront);
  invgaloismult ig(rcon[31:24], invrconFront);

  always_comb
    if      (pivot) nextrcon = rcon;
    else if (done1) nextrcon = {invrconFront, 24'b0};
    else            nextrcon = {rconFront, 24'b0};

  // temp block logic
  assign transform = (done1)? (block[31:0]^block[63:32]) : block[31:0];
  rotate #(1, 4, 8) rw(transform, rotTemp);
  subword sw(rotTemp, subTemp);
  // osubword           sw(1'b0, rotTemp, subTemp);

  assign rconTemp = subTemp ^ nextrcon;

  always_comb begin
    temp[127:96] = block[127:96] ^ rconTemp;
    if (done1) begin temp[95:0] = block[95:0] ^ block[127:32]; end
    else begin
      temp[95:64]  = (block[95:64]  ^ temp[127:96]);
      temp[63:32]  = (block[63:32]  ^ temp[95:64]);
      temp[31:0]   = (block[31:0]   ^ temp[63:32]);
    end
  end

  // next expansion block and output logic
  assign nextBlock = temp;
  assign roundKey = block;

endmodule
