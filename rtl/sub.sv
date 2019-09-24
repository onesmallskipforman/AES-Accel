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

module subbytes(input  logic [127:0] a,
                output logic [127:0] y);

  subword sw0(a[127:96], y[127:96]);
  subword sw1(a[95:64],  y[95:64]);
  subword sw2(a[63:32],  y[63:32]);
  subword sw3(a[31:0],   y[31:0]);

endmodule

/*
  Below is a module for sbox substitution for every byte in a
  32-bit word.

  Inputs:
    word[31:0]:   32-bit word

  Outputs:
    subbed[31:0]: 32-bit byte-substituted word
*/

module subword (input  logic [31:0] word,
                output logic [31:0] subbed);

  // sbyte sb0(word[31:24], subbed[31:24]);
  // sbyte sb1(word[23:16], subbed[23:16]);
  // sbyte sb2(word[15:8],  subbed[15:8]);
  // sbyte sb3(word[7:0],   subbed[7:0]);


  sbox sb0(word[31:24], subbed[31:24]);
  sbox sb1(word[23:16], subbed[23:16]);
  sbox sb2(word[15:8],  subbed[15:8]);
  sbox sb3(word[7:0],   subbed[7:0]);

endmodule


// module sbyte (input logic [7:0] a,
//               output logic [7:0] y);
  
//   logic [7:0] b;
//   assign c = 8'h63;

//   logic [7:0] sbox[0:255];
//   initial $readmemh("../InvAES-Accel/rtl/sbox.txt", sbox);
//   assign b = sbox[a];

//   genvar i;
//   generate
//     for (i = 0; i < 8; i++) begin: bitsubs
//       assign y[i] = b[i] ^ b[(i+4)%8] ^ b[(i+5)%8] ^ b[(i+6)%8] ^ b[(i+7)%8] ^ c[i];
//     end
//   endgenerate

// endmodule


/*
  Below is a module for sbox the infamous AES byte
  substitution with magic numbers.

  Inputs:
    a[7:0]: input byte

  Outputs:
    y[7:0]: sbox substituted byte
*/

module sbox(input  logic [7:0] a,
            output logic [7:0] y);

  // sbox implemented as a ROM
  logic [7:0] sbox[0:255];

  initial $readmemh("../InvAES-Accel/rtl/sbox.txt", sbox);
  assign y = sbox[a];

endmodule


