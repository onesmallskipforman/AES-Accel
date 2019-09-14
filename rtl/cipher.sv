/*
  Robert "Skipper" Gonzalez
  sgonzalez@g.hmc.edu
  12/10/2019
  AES cipher module

  Below is a module that performs the cipher function for 128-bit AES
  encryption. This module runs 4 steps of the 44-step algorithm at a time,
  allowing for the encryption to complete in 11 cycles.

  Inputs:
    clk:               sytem clock signal
    reset:             reset signal to restart cypher process
    done:              done bit signalling encryption completed
    wBlock[127:0]:     block of Nk=4 words generated in a cycle of key expansion
    in[127:0]:         128-bit message to encrypt

  Outputs:
    out[127:0]:        128-bit encrypted message

  Internal Variables:
    nextStm[127:0]: AES four-word state matrix
    stm[127:0]:     state matrix from last cycle (last clock tick)
    bStm[127:0]:    subBytes transform applied to stm
    hStm[127:0]:    mixColumns transform applied to bStm
    mStm[127:0]:    addRoundKey transform applied to hStm
*/

module cipher (input  logic         clk,
               input  logic         reset,
               input  logic         done,
               input  logic [127:0] wBlock,
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

  always_comb
    case(state)
      S0: if (reset) nextstate = S0;
          else       nextstate = S1;
      S1: if (done)  nextstate = S2;
          else       nextstate = S1;
      S2: if (reset) nextstate = S0;
          else       nextstate = S2;
      default:       nextstate = S0;
    endcase

  subbytes    sb1(stm, bStm);
  shiftrows   sr1(bStm, hStm);
  mixcolumns  mx1(hStm, mStm);

  always_comb
    if      ((state == S0) & (nextstate == S1))   nextStm = in^wBlock;   // cycle 1
    else if ((state == S1) & (nextstate == S1))   nextStm = mStm^wBlock; // cycles 2-10
    else if ((state == S1) & (nextstate == S2))   nextStm = hStm^wBlock; // cycle 11
    else                                          nextStm = stm;         // resting

  // assign nextStm = ( !done & (state == S1) )? mStm^wBlock:stm;
  assign out = nextStm;

endmodule
