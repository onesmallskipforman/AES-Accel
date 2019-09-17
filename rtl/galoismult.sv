/*
  Robert "Skipper" Gonzalez
  sgonzalez@g.hmc.edu
  12/10/2019
  galois mult module

  Below is a module for performing multiplication by x^N in
  GF(2^8). This is achieved by a left shift followed by an XOR
  if the result overflows. Uses irreducible polynomial
  x^8+x^4+x^3+x+1 = 00011011.

  Parameters:
    N: power of x to multiply a by in GF(2^8)

  Inputs:
    a[31:0]:  state matrix column

  Outputs:
    y[127:0]: transformed column
*/

module galoismult #(parameter N = 1)
                   (input  logic [7:0] a,
                    output logic [7:0] y);

  genvar i;
  logic [8*(N+1)-1:0] powers, ashift;

  generate
    assign powers[0 :+ 8] = a;
    for (i = 1; i < N; i++) begin : galois
      assign ashift[i*8 :+ 8] = (powers[(i-1)*8 :+ 8] << 1);
      assign powers[i*8 :+ 8] = ({powers[(i-1)*8 :+ 8]}[7])?
        (ashift[i*8 :+ 8] ^ 8'b00011011) : ashift[i*8 :+ 8];
    end

  endgenerate

  assign y = powers[(i-1)*8 :+ 8];
endmodule