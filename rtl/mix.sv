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

module mixcolumns(input  logic [127:0] a,
                  output logic [127:0] y);

  mixcolumn mc0(a[127:96], y[127:96]);
  mixcolumn mc1(a[95:64],  y[95:64]);
  mixcolumn mc2(a[63:32],  y[63:32]);
  mixcolumn mc3(a[31:0],   y[31:0]);

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

module mixcolumn(input  logic [31:0] a,
                 output logic [31:0] y);

  logic [7:0] a0, a1, a2, a3, y0, y1, y2, y3, t0, t1, t2, t3, tmp;

  assign {a0, a1, a2, a3} = a;
  assign tmp = a0 ^ a1 ^ a2 ^ a3;

  galoismult gm0(a0^a1, t0);
  galoismult gm1(a1^a2, t1);
  galoismult gm2(a2^a3, t2);
  galoismult gm3(a3^a0, t3);

  assign y0 = a0 ^ tmp ^ t0;
  assign y1 = a1 ^ tmp ^ t1;
  assign y2 = a2 ^ tmp ^ t2;
  assign y3 = a3 ^ tmp ^ t3;
  assign y = {y0, y1, y2, y3};
endmodule
