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

module keyexpansion #(parameter K = 128)
               (input  logic          clk, reset,
                input  logic          done,
                input  logic [K-1:0]  key,
                output logic [127:0]  roundKey);

  logic [31:0]  rcon, nextrcon, transform, rotTemp, subTemp, rconTemp, subTransform, subOrgTemp;
  logic [K-1:0] block, temp, nextBlock;
  logic [7:0]   rconFront, invrconFront;

  typedef enum logic [1:0] {S0, S1, S2, S3} statetype;
  statetype state, nextstate;

  typedef enum logic {FWD, BWD} dirstatetype;
  dirstatetype dirstate, nextdirstate;

  always_ff @(posedge clk)
    if (reset) begin
      state       <= S0;
      block       <= 32'b0;
      rcon        <= 32'h8d000000;
    end else if (!done) begin
      state       <= nextstate;
      block       <= nextBlock;
      rcon        <= nextrcon;
    end

  // next state logic
  always_comb
    case(state)
      S0:                     nextstate = S1;
      S1: if      (K == 128)  nextstate = S1;
          else if (K == 256)  nextstate = S2;
          else                nextstate = S3;
      S2:                     nextstate = S1;
      S3:                     nextstate = S2;
      default:                nextstate = S0;
    endcase

  // next round constant (rcon for current temp transform) logic
  galoismult    gm(rcon[31:24], rconFront);

  always_comb
    if ((state == S0) | ((state == S1) & (K != 128))) nextrcon = rcon;
    else                                              nextrcon = {rconFront, 24'b0};

  // temp block logic
  assign transform = block[31:0];
  rotate #(1, 4, 8) rw(transform, rotTemp);
  subword           sw(rotTemp, subTemp);
  assign rconTemp       = subTemp         ^ nextrcon;
  assign temp[K-1:K-32] = block[K-1:K-32] ^ rconTemp;

  genvar i;
  generate
    for (i = K-32; i > 0; i=i-32) begin: tempAssign
      // unique case for 256-bit expansion block
      if ( (K == 256) && (i == 128) ) begin
        assign subTransform = temp[i+32-1:i];
        subword so(subTransform, subOrgTemp);
        assign temp[i-1:i-32]  = block[i-1:i-32]^subOrgTemp;
      end else begin
        assign temp[i-1:i-32] = block[i-1:i-32]^temp[i+32-1:i];
      end
    end
  endgenerate

  // next expansion block logic
  always_comb
    if       (state == S0)               nextBlock = key;
    else if ((K != 128) & (state == S1)) nextBlock = block;
    else                                 nextBlock = temp;

  // output logic
  always_comb
    case(state)
      S0: roundKey = 32'b0;
      S1: roundKey = block[K-1: K-128];
      S2: roundKey = block[127:0];
      S3: roundKey = {block[63:0], temp[K-1: K-64]};
      default: roundKey = 32'b0;
    endcase

endmodule
