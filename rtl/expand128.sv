/*
  Robert "Skipper" Gonzalez
  sgonzalez@g.hmc.edu
  12/10/2019
  AES 128-bit key expansion

  Below is a module that performs the key expansion function for 128-bit AES
  encryption. This module runs 4 steps of the algorithm at a time,
  allowing 128-bit encyption to complete in 11 cycles.

  Inputs:
    clk:        sytem clock signal
    reset:      reset signal to restart cypher process
    done:       bit signalling encryption complete
    key[127:0]: 128-bit encryption key

  Outputs:
    block[127:0]: 4-word round key generated in current cycle of expansion

  Internal Variables:
    nextBlock[127:0]: next block of 4 words generated for the expanded key
    rcon[31:0]:       round constant word array
    nextrcon[31:0]:   next round constant word array
    rotTemp[31:0]:    rotWord transform applied to block
    subTemp[31:0]:    subWord transform applied to rotTemp
    rconTemp[31:0]:   XOR between subWord and rcon
    rconfront[7:0]:   First word in rcon after galois mult to nextrcon
*/

module expand128 (input  logic          clk, reset,
                  input  logic          done,
                  input  logic [127:0]  key,
                  output logic [127:0]  block);

  logic [127:0] nextBlock;
  logic [31:0]  rcon, nextrcon, rotTemp, subTemp, rconTemp;
  logic [7:0]   rconFront;

  always_ff @(posedge clk) begin
    // block <= nextBlock;
    if (reset) begin
      block <= key;
      rcon  <= 32'h8d000000;
    end else if (!done) begin
      block <= nextBlock;
      rcon  <= nextrcon;
    end
  end

  // next round constant (rcon for current temp transform) logic
  galoismult gm(rcon[31:24], rconFront);
  assign nextrcon = {rconFront, 24'b0};

  // next block logic
  rotate #(1, 4, 8) rw(block[31:0], rotTemp);
  subword           sw(rotTemp, subTemp);

  assign rconTemp = subTemp ^ nextrcon;

  always_comb begin
    nextBlock[127:96] = block[127:96]  ^ rconTemp;
    nextBlock[95:64]  = (block[95:64]  ^ nextBlock[127:96]);
    nextBlock[63:32]  = (block[63:32]  ^ nextBlock[95:64]);
    nextBlock[31:0]   = (block[31:0]   ^ nextBlock[63:32]);
  end
endmodule
