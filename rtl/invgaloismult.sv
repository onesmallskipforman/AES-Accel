/*
  Robert "Skipper" Gonzalez
  sgonzalez@g.hmc.edu
  12/10/2019
  galois mult module

  Below is a module for performing multiplication by x^-N in
  GF(2^8). This is achieved by a right shift followed by an XOR
  if the result overflows. Uses multiplicative inverse of x = {02}
  in GF(2^8), x^7+x^3+x^2+1 = {8d} = 10001101.

  Parameters:
    N: negative power of x to multiply a by in GF(2^8)

  Inputs:
    a[31:0]:  original byte

  Outputs:
    y[127:0]: byte multiplied by x^-N in GF(2^8)

  Internal Variables:
    powers[8*(N+1)-1:0]: 8N-bit object that holds input multiplied by negative powers of x
    ashift[8*(N+1)-1:0]: temporary placeholder for last power shifted left
*/

module invgaloismult #(parameter N = 1)
                      (input  logic [7:0] a,
                       output logic [7:0] y);

  genvar i;
  logic [8*(N+1)-1:0] powers;
  logic [8*N-1:0]     ashift;

  generate
    assign powers[0 +: 8] = a;
    for (i = 1; i < N+1; i++) begin : galois
      assign ashift[(i-1)*8 +: 8] = (powers[(i-1)*8 +: 8] >> 1);
      assign powers[i*8 +: 8] = (powers[(i-1)*8])?
		(ashift[(i-1)*8 +: 8] ^ 8'b10001101) : ashift[(i-1)*8 +: 8];
    end

  endgenerate

  assign y = powers[N*8 +: 8];
endmodule
