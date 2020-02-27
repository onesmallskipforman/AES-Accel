/*
  Robert "Skipper" Gonzalez
  sgonzalez@g.hmc.edu
  12/10/2019
  AES 256-bit key expansion

  Below is a module that performs the key expansion function for 256-bit AES
  encryption. This module runs 4 steps of the algorithm at a time,
  allowing 256-bit encyption to complete in 15 cycles.

  Inputs:
    clk:        sytem clock signal
    reset:      reset signal to restart cypher process
    done:       bit signalling encryption complete
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
    tosub[31:0]:       4 words to be substituted into subTemp
*/

module expand256 (input  logic          clk, reset,
                  input  logic          done,
                  input  logic [255:0]  key,
                  output logic [127:0]  roundKey);

  logic [31:0]  rcon, nextrcon, transform, rotTemp, subTemp, rconTemp, tosub;
  logic [255:0] block, nextBlock;
  logic [127:0] temp;
  logic [7:0]   rconFront;

  typedef enum logic {S0, S1} statetype;
  statetype state, nextstate;

  always_ff @(posedge clk)
    if (reset) begin
      state       <= S0;
      block       <= key;
      rcon        <= 32'h8d000000;
    end else if (!done) begin
      state       <= nextstate;
      block       <= nextBlock;
      rcon        <= nextrcon;
    end

  // next state logic
  always_comb
    case (state)
      S0:      nextstate = S1;
      S1:      nextstate = S0;
      default: nextstate = S0;
    endcase

  // next round constant (rcon for current temp transform) logic
  galoismult    gm(rcon[31:24], rconFront);
  assign nextrcon = (state == S0)? {rconFront, 24'b0} : rcon;

  // temp block logic
  rotate #(1, 4, 8) rw(block[31:0], rotTemp);
  assign tosub = (state == S0)? rotTemp : block[31:0];
  subword sw(tosub, subTemp);
  assign rconTemp = subTemp ^ nextrcon;

  always_comb begin
    temp[127:96] = (state == S0)? (block[255:224] ^ rconTemp) : (block[255:224] ^ subTemp);
    temp[95:64]  = (block[223:192]  ^ temp[127:96]);
    temp[63:32]  = (block[191:160]  ^ temp[95:64]);
    temp[31:0]   = (block[159:128]  ^ temp[63:32]);
  end

  // next expansion block and output logic
  assign nextBlock = {block[127:0], temp};
  assign roundKey  = block[255: 128];

endmodule
