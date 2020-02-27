/*
  Robert "Skipper" Gonzalez
  sgonzalez@g.hmc.edu
  12/10/2019
  AES cipher module

  Below is a module that performs the cipher function for AES
  encryption. This module runs 4 steps of the algorithm at a time,
  allowing 128-, 192-, and 256-bit encyption to complete
  11 cycles, 13 cycles, and 15 cycles, respectively.

  Inputs:
    clk:             sytem clock signal
    reset:           reset signal to restart cypher process
    done:            done/disable bit signalling encryption completed
    roundKey[127:0]: block of 4 words generated in a cycle of key expansion
    in[127:0]:       128-bit message to encrypt

  Outputs:
    out[127:0]: 128-bit encrypted message

  Internal Variables:
    nextStm[127:0]: AES four-word state matrix
    stm[127:0]:     state matrix from last cycle (last clock tick)
    bStm[127:0]:    subBytes transform applied to stm
    hStm[127:0]:    shiftrows transform applied to bStm
    mStm[127:0]:    mixColumns transform applied to hStm
*/

module cipher (input  logic         clk,
               input  logic         reset,
               input  logic         done,
               input  logic [127:0] roundKey,
               input  logic [127:0] in,
               output logic [127:0] out);

  logic [127:0] nextStm, stm, bStm, hStm, mStm;

  typedef enum logic [1:0] {S0, S1, S2} statetype;
  statetype state, nextstate;

  always_ff @(posedge clk)
    if (reset) begin
      state <= S0;
      stm   <= 0;
    end else begin
      state <= nextstate;
      stm   <= nextStm;
    end

  // next state logic
  always_comb
    case(state)
      S0:            nextstate = S1;
      S1: if (done)  nextstate = S2;
          else       nextstate = S1;
      S2:            nextstate = S2;
      default:       nextstate = S0;
    endcase

  // cipher state transformation logic
  subbytes    sb1(stm, bStm);
  shiftrows   sr1(bStm, hStm);
  mixcolumns  mx1(hStm, mStm);

  // next cipher state logic
  always_comb
    if       (state == S0)          nextStm = in   ^ roundKey; // cycle 1
    else if ((state == S1) & !done) nextStm = mStm ^ roundKey; // cycles 2-10
    else if ((state == S1) &  done) nextStm = hStm ^ roundKey; // cycle 11
    else                            nextStm = stm;             // resting

  // output logic
  assign out = nextStm;

endmodule
