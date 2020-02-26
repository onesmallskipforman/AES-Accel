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
  logic wasdone;

  always_ff @(posedge clk) begin
    wasdone <= done;
    if (reset) stm <= in^roundKey;
    else       stm <= nextStm;
  end

  // inverse cipher state transformation logic
  invshiftrows   isr1(stm, ihStm);
  invsubbytes    isb1(ihStm, ibStm);
  assign rStm = ibStm ^ roundKey;
  invmixcolumns  imx1(rStm, imStm);

  // next inverse cipher state logic
  always_comb
    if      (!done)    nextStm = imStm; // cycles 2-10
    else if (!wasdone) nextStm = rStm;  // cycle 11
    else               nextStm = stm;   // resting

  // output logic
  assign out = nextStm;

endmodule
