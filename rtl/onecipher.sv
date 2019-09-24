/*
  Robert "Skipper" Gonzalez
  sgonzalez@g.hmc.edu
  12/10/2019
  AES cipher module

  Below is a module that performs the cipher function for 128-bit AES
  encryption. This module runs 4 steps of the algorithm at a time,
  allowing 128-, 192-, and 128-bit encyption encryption to complete
  11 cycles, 13 cycles, and 15 cycles, respectively.

  Inputs:
    clk:               sytem clock signal
    reset:             reset signal to restart cypher process
    done:             done/disable bit signalling encryption completed
    roundKey[127:0]:   block of Nk=4 words generated in a cycle of key expansion
    in[127:0]:         128-bit message to encrypt

  Outputs:
    out[127:0]:        128-bit encrypted message

  Internal Variables:
    nextStm[127:0]: AES four-word state matrix
    stm[127:0]:     state matrix from last cycle (last clock tick)
    bStm[127:0]:    subBytes transform applied to stm
    hStm[127:0]:    shiftrows transform applied to bStm
    mStm[127:0]:    mixColumns transform applied to hStm
*/

module ocipher (input  logic         clk,
               input  logic         reset,
               input  logic         done, dir,
               input  logic [127:0] roundKey,
               input  logic [127:0] in,
               output logic [127:0] out);

  logic [127:0] nextStm, stm, bStm, hStm, mStm, toshift, shifted, tomix;

  typedef enum logic [1:0] {START, S0, S1, S2} statetype;
  statetype state, nextstate;

  always_ff @(posedge clk)
    if (reset) begin
      state <= START;
      stm   <= 0;
    end else if (!done) begin
      state <= nextstate;
      stm   <= nextStm;
    end

  // next state logic
  always_comb
    case(state)
      START:         nextstate = S0;
      S0:            nextstate = S1;
      S1: if (done)  nextstate = S2;
          else       nextstate = S1;
      S2:            nextstate = S2;
      default:       nextstate = S0;
    endcase

  // cipher state transformation logic
  osubbytes   sb1(dir, stm, bStm);
  assign toshift = (dir)? {bStm[31:0], bStm[63:32], bStm[95:64], bStm[127:96]} : bStm;
  shiftrows   sr1(toshift, shifted);
  assign hStm = (dir)? {shifted[31:0], shifted[63:32], shifted[95:64], shifted[127:96]} : shifted;

  assign tomix = (dir)? (hStm^roundKey) : hStm; 
  omixcolumns  mx1(dir, tomix, mStm);

  // next cipher state logic
  always_comb
    if       (state == S0)                        nextStm = in^roundKey; // cycle 1
    else if ((state == S1) & (nextstate == S1))   nextStm = (dir)? mStm : (mStm^roundKey); // cycles 2-10
    else if ((state == S1) & done)               nextStm = hStm^roundKey; // cycle 11
    else                                          nextStm = stm;             // resting

  // output logic
  assign out = nextStm;

endmodule
