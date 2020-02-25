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

module invsubbytes(input  logic [127:0] a,
                   output logic [127:0] y);

  invsubword isw0(a[127:96], y[127:96]);
  invsubword isw1(a[95:64],  y[95:64]);
  invsubword isw2(a[63:32],  y[63:32]);
  invsubword isw3(a[31:0],   y[31:0]);

endmodule

/*
  Below is a module for sbox substitution for every byte in a
  32-bit word.

  Inputs:
    word[31:0]:   32-bit word

  Outputs:
    subbed[31:0]: 32-bit byte-substituted word
*/

module invsubword (input  logic [31:0] word,
                   output logic [31:0] subbed);

  invsbox isb0(word[31:24], subbed[31:24]);
  invsbox isb1(word[23:16], subbed[23:16]);
  invsbox isb2(word[15:8],  subbed[15:8]);
  invsbox isb3(word[7:0],   subbed[7:0]);

endmodule

/*
  Below is a module for sbox the infamous AES byte
  substitution with magic numbers.

  Inputs:
    a[7:0]: input byte

  Outputs:
    y[7:0]: sbox substituted byte
*/

module invsbox(input  logic [7:0] a,
               output logic [7:0] y);

  // sbox implemented as a ROM
  logic [7:0] sbox[0:255];

  initial $readmemh("../AES-Accel/rtl/invsbox.txt", sbox);
  assign y = sbox[a];

endmodule
