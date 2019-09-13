
/*
  Robert "Skipper" Gonzalez
  sgonzalez@g.hmc.edu
  11/30/2018
  clk_gen module

  Below is the module which outputs an enabled and synchronous reset
  clock that is slower than an input clock. The output clock speed is
  determined by parameters. Speeds higher than the input clock
  speed are invalid.

  Parameters:
    sc_f:  The desired slower clock frequency.
    clk_f: The input clock (clk) frequency.

  Inputs:
    clk:    clock signal
    reset:  reset signal
    en:     enable signal

  Outputs:
    sc:     slower clock signal
*/

module clk_gen  #(parameter sc_f = 10**6,
                  parameter clk_f = 40 * (10**6) )
                 (input  logic clk,
                  input  logic reset,
                  input  logic en,
                  output logic sc);

  parameter sc_bits = $clog2(clk_f/sc_f); // number of bits to use
  logic [sc_bits-1:0] inc;                // variable incremented by counter

  // implement counter
  counter #(sc_bits) c(clk, reset, en, inc);

  // assign sc to correct bit of inc
  assign sc = inc[sc_bits];

endmodule
