/*
  Robert "Skipper" Gonzalez
  sgonzalez@g.hmc.edu
  09/12/2018
  generalized, parameterized rotate module

  Below is a module that takes an MN-bit input, or M-long input
  with N-long elements, and rotates that input left by R of
  the N-bit elements.

  Parameters:
    R: number of N-bit rotations
    M: number of N-bit objects the input holds
    N: size of each element of the input

  Inputs:
    word[32:0]:   input word

  Outputs:
    rotated[7:0]: rotated word

  Internal Variables:
    shift:        the number of N-bit rotations modulo M
*/

module rotate #(parameter R = 1,
                parameter M = 1,
                parameter N = 1)
               (input  logic [N*M-1:0] a,
                output logic [N*M-1:0] y);

  parameter shift = R % M;

  assign y = {a[0 +: N*(M - shift)], a[N*(M - shift) +: N*shift]};

endmodule
