/*
  Robert "Skipper" Gonzalez
  sgonzalez@g.hmc.edu
  12/10/2019
  AES 128-bit key expansion

  Below is a module that performs forward and reverse key expansion
  for K-bit AES decryption. This module runs 4 steps of the algorithm at a time,
  allowing 128-, 192-, and 128-bit encyption expansion to complete
  11 cycles, 13 cycles, and 15 cycles, respectively.

  Parameters:
    K:                 the length of the key

  Inputs:
    clk:               sytem clock signal
    reset:             reset signal to restart cypher process
    done1:             done bit signalling forward key expansion complete
    key[K-1:0]:        K-bit encryption key

  Outputs:
    nextBlock[127:0]:     block of four words generated in current cycle of key expansion

  Internal Variables:
    rcon[31:0]:        round constant word array for the first step of the current cycle
    nextrcon[31:0]:    round constant word array for the first step of the next cycle
    transform[31:0]:   word to be transformed by rotWord, subWord, and XOR with rcon
    rotTemp[31:0]:     rotWord transform applied to transform
    subTemp[31:0]:     subWord transform applied to rotTemp
    rconTemp[31:0]:    XOR between subWord and rcon
    block[127:0]:      last word from the expansion block from the last cycle
    temp[127:0]:       temporary storage for nextBlock for cycles 2-10
    rconFront[7:0]:    First word in rcon after multiplication with x in GF(8)
    invrconFront[7:0]: First word in rcon after multiplication with x^-1 in GF(8)
*/

module expand #(parameter K = 128)
               (input  logic          clk, reset,
                input  logic          done1,
                input  logic          done2,
                input  logic [K-1:0]  key,
                output logic [127:0]  roundKey);

  logic [31:0]  rcon, nextrcon, transform, rotTemp, subTemp, rconTemp, subTransform, subOrgTemp;
  logic [K-1:0] block, temp, nextBlock;
  logic [7:0]   rconFront, invrconFront;
  logic         wasdone1;

  typedef enum logic [1:0] {S0, S1, S2, S3} statetype;
  statetype state, nextstate;

  typedef enum logic {FWD, BWD} dirstatetype;
  dirstatetype dirstate, nextdirstate;

  always_ff @(posedge clk)
    if (reset) begin
      state       <= S0;
      block       <= 32'b0;
      rcon        <= 32'h8d000000;
      wasdone1    <= 1'b0;
    end else if (!done2) begin
      state       <= nextstate;
      block       <= nextBlock;
      rcon        <= nextrcon;
      wasdone1    <= done1;
    end

  // next state logic
  always_comb
    case(state)
      S0:                                 nextstate = S1;
      S1: if       (K == 128)             nextstate = S1;
          else if ((K == 256) | done1)  nextstate = S2;
          else                            nextstate = S3;
      S2: if      ((K == 256) | !done1) nextstate = S1;
          else                            nextstate = S3;
      S3: if       (done1)              nextstate = S1;
          else                            nextstate = S2;
      default:                            nextstate = S0;
    endcase

  // next round constant (rcon for current temp transform) logic
  galoismult    gm(rcon[31:24], rconFront);
  invgaloismult ig(rcon[31:24], invrconFront);

  always_comb
    if      ( done1 & !wasdone1 )         nextrcon = rcon;
    else if ( (state == S1) | (state == S3) ) nextrcon = (done1)? {invrconFront, 24'b0} : {rconFront, 24'b0};
    else                                      nextrcon = rcon;

  // temp block logic
  assign transform = (done1)? (block[31:0]^block[63:32]) : block[31:0];
  rotate #(1, 4, 8) rw(transform, rotTemp);
  subword           sw(rotTemp, subTemp);
  assign rconTemp       = subTemp         ^ nextrcon;
  assign temp[K-1:K-32] = block[K-1:K-32] ^ rconTemp;

  genvar i;
  generate
    for (i = K-32; i > 0; i=i-32) begin: tempAssign
      // unique case for 256-bit expansion block
      if ( (K == 256) && (i == 128) ) begin
        assign subTransform = (!done1)? temp[i+32-1:i] : block[i+32-1:i];
        subword so(subTransform, subOrgTemp);
        assign temp[i-1:i-32]  = block[i-1:i-32]^subOrgTemp;
      end else begin
        assign temp[i-1:i-32] = (!done1)? (block[i-1:i-32]^temp[i+32-1:i]) : (block[i-1:i-32]^block[i+32-1:i]);
      end
    end
  endgenerate

  // next expansion block logic
  always_comb
    if      ( state == S0 )                 nextBlock = key;
    else if ((state == S1) | (state == S3)) nextBlock = temp;
    else                                    nextBlock = block;

  // output logic
  always_comb
    case(state)
      S0: roundKey = 32'b0;
      S1: roundKey = block[K-1: K-128];              // first four words of temp XOR'ed with last expansion block
      S2: roundKey = block[127:0];                   // last four words of last key block
      S3: roundKey = {block[63:0], temp[K-1: K-64]}; // last two words of last expansion block, first two of current block
      default: roundKey = 32'b0;
    endcase

endmodule
