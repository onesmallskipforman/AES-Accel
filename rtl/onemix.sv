/*
  Robert "Skipper" Gonzalez
  sgonzalez@g.hmc.edu
  12/10/2019
  column mixing algorithm modules
*/

/*
  Below is a module for the mixcolumns transform on the
  AES encryption state matrix, as seen in Section 5.1.3, Figure 9
  of FIPS-197 (see docs)

  Inputs:
    a[127:0]: state matrix

  Outputs:
    y[127:0]: mixcolumns-transformed state matrix
*/

module omixcolumns(input logic dir,
                  input  logic [127:0] a,
                  output logic [127:0] y);

  omixcolumn mc0(dir, a[127:96], y[127:96]);
  omixcolumn mc1(dir, a[95:64],  y[95:64]);
  omixcolumn mc2(dir, a[63:32],  y[63:32]);
  omixcolumn mc3(dir, a[31:0],   y[31:0]);

endmodule

/*
  Below is a module for the mixcolumns transform on the
  AES encryption state matrix. Seen EQ(4) from E. Ahmed et al,
  Lightweight Mix Columns Implementation for AES, AIC09 for this
  hardware implementation (found in docs).

  Inputs:
    a[31:0]:  state matrix column

  Outputs:
    y[127:0]: transformed column
*/


module omixcolumn(input logic dir,
                    input  logic [31:0] a,
                  output logic [31:0] y);

  logic [7:0] a123x3, a0x1, a1x1, a2x1, a3x1, a0x2, a1x2, a2x2, a3x2, a0, a1, a2, a3;
  logic [7:0] tmp, y0, y1, y2, y3;
  assign {a0, a1, a2, a3} = a;
  assign tmp = a0 ^ a1 ^ a2 ^ a3;

  // sum of bytes multiplied by x^3
  galoismult #(3) g0(tmp, a123x3);

  // bytes multiplied by x^2
  galoismult #(2) g1(a0, a0x2);
  galoismult #(2) g2(a1, a1x2);
  galoismult #(2) g3(a2, a2x2);
  galoismult #(2) g4(a3, a3x2);

  // bytes multiplied by x
  galoismult #(1) g5(a0, a0x1);
  galoismult #(1) g6(a1, a1x1);
  galoismult #(1) g7(a2, a2x1);
  galoismult #(1) g8(a3, a3x1);

  assign y0 = (dir)? (a123x3 ^ a0x2 ^ a2x2 ^ a0x1 ^ a1x1 ^ tmp ^ a0) : (a0^tmp^a0x1^a1x1);
  assign y1 = (dir)? (a123x3 ^ a1x2 ^ a3x2 ^ a1x1 ^ a2x1 ^ tmp ^ a1) : (a1^tmp^a1x1^a2x1);
  assign y2 = (dir)? (a123x3 ^ a2x2 ^ a0x2 ^ a2x1 ^ a3x1 ^ tmp ^ a2) : (a2^tmp^a2x1^a3x1);
  assign y3 = (dir)? (a123x3 ^ a3x2 ^ a1x2 ^ a3x1 ^ a0x1 ^ tmp ^ a3) : (a3^tmp^a3x1^a0x1);

  assign y = {y0, y1, y2, y3};
endmodule
