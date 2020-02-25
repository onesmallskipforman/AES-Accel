/*
  Robert "Skipper" Gonzalez
  sgonzalez@g.hmc.edu
  12/10/2019
  sbox substitution modules
*/

/*
  Below is a module for sbox substitution for every byte in a
  128-bit AES state matrix.

  Inputs:
    a[127:0]: 128-bit state matrix

  Outputs:
    y[127:0]: 128-bit byte-substituted state matrix
*/

module osubbytes(input logic dir, 
                  input  logic [127:0] a,
                output logic [127:0] y);

  osubword sw0(dir, a[127:96], y[127:96]);
  osubword sw1(dir, a[95:64],  y[95:64]);
  osubword sw2(dir, a[63:32],  y[63:32]);
  osubword sw3(dir, a[31:0],   y[31:0]);

endmodule

/*
  Below is a module for sbox substitution for every byte in a
  32-bit word.

  Inputs:
    word[31:0]:   32-bit word

  Outputs:
    subbed[31:0]: 32-bit byte-substituted word
*/

module osubword (input logic dir, 
                input  logic [31:0] word,
                output logic [31:0] subbed);

  osbyte sb0(dir, word[31:24], subbed[31:24]);
  osbyte sb1(dir, word[23:16], subbed[23:16]);
  osbyte sb2(dir, word[15:8],  subbed[15:8]);
  osbyte sb3(dir, word[7:0],   subbed[7:0]);

endmodule


module osbyte (input logic dir, 
              input logic [7:0] a,
              output logic [7:0] y);
  
  logic [7:0] b, invaff, aff, index, tbl;
  parameter logic [7:0] c = 8'h63;
  parameter logic [7:0] invc = 8'h05;

  genvar i;
  generate
    for (i = 0; i < 8; i++) begin: invaffine
      assign invaff[i] = a[(i+2)%8] ^ a[(i+5)%8] ^ a[(i+7)%8] ^ invc[i];
    end
  endgenerate

  assign index = (dir)? invaff : a;

  logic [7:0] sbox[0:255];
  initial $readmemh("../InvAES-Accel/rtl/inv.txt", sbox);

  assign tbl = sbox[index];

  generate
    for (i = 0; i < 8; i++) begin: affine
      assign aff[i] = tbl[i] ^ tbl[(i+4)%8] ^ tbl[(i+5)%8] ^ tbl[(i+6)%8] ^ tbl[(i+7)%8] ^ c[i];
    end
  endgenerate

  assign y = (dir)? tbl : aff;

endmodule
