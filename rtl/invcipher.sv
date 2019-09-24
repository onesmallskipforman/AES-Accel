/*
  Robert "Skipper" Gonzalez
  sgonzalez@g.hmc.edu
  12/10/2019
  AES cipher module

  Below is a module that performs the inverse cipher function for 128-bit AES
  encryption. This module runs 4 steps of the 44-step algorithm at a time,
  allowing for the encryption to complete in 11 cycles.

  Inputs:
    clk:               sytem clock signal
    reset:             reset signal to restart cypher process
    done:              done bit signalling encryption completed
    roundKey[127:0]:     block of Nk=4 words generated in a cycle of key expansion
    in[127:0]:         128-bit message to encrypt

  Outputs:
    out[127:0]:        128-bit encrypted message

  Internal Variables:
    nextStm[127:0]:  AES four-word state matrix
    stm[127:0]:      state matrix from last cycle (last clock tick)
    ihStm[127:0]:    inverse shiftrows transform applied to stm
    ibStm[127:0]:    inverse subBytes transform applied to ihStm
    rStm[127:0]:     addRoundKey transform applied to ibStm
    imStm[127:0]:    inverse mixColumns transform applied to hStm
*/

module invcipher (input  logic         clk,
                  input  logic         reset,
                  input  logic         done,
                  input  logic [127:0] roundKey,
                  input  logic [127:0] in,
                  output logic [127:0] out);

  logic [127:0] nextStm, stm, ibStm, ihStm, imStm, rStm;

  typedef enum logic [1:0] {S0, S1, S2} statetype;
  statetype state, nextstate;

  always_ff @(posedge clk)
    if (reset) begin
      state <= S0;
      stm   <= 0;
    end else if (!done) begin
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

  // inverse cipher state transformation logic
  invshiftrows   isr1(stm, ihStm);
  invsubbytes    isb1(ihStm, ibStm);
  assign rStm = ibStm ^ roundKey;
  invmixcolumns  imx1(rStm, imStm);

  // next inverse cipher state logic
  always_comb
    if       (state == S0)                        nextStm = in^roundKey; // cycle 1
    else if ((state == S1) & (nextstate == S1))   nextStm = imStm;       // cycles 2-10
    else if ((state == S1) & done)                nextStm = rStm;        // cycle 11
    else                                          nextStm = stm;         // resting

  // output logic
  assign out = nextStm;

endmodule
