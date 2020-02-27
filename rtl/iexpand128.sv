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
