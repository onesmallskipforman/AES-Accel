/*
  Robert "Skipper" Gonzalez
  sgonzalez@g.hmc.edu
  09/12/2018
  counter module

  Below is a generalizd, synchronous reset, counter module.
  This module, when enabled, increments a value q by inc
  upon rising edge of the clock.

  Parameters:
    N: The number of bits for our incrementable variable q
    M: The number of bits for our increment amount inc

  Inputs:
    clk:        clock signat
    reset:      reset signal
    en:         enable signal
    inc[M-1:0]: amount to increment counter by

  Outputs:
    q[N-1:0]: N-bit variable being incremented
*/

module counter#(parameter N=8,
                parameter M=1)
               (input  logic         clk,
                input  logic         reset,
                input  logic         en,
                input  logic [M-1:0] inc,
                output logic [N-1:0] q);

  // ensure counter only makes changes as the tick of
  // the clock or press of reset
  // restart q if reset, otherwise increment
  always_ff @(posedge clk)
    if      (reset)    q <= 0;
    else if (en)       q <= q+inc;
    else               q <= q;

endmodule
