/*
  Robert "Skipper" Gonzalez
  sgonzalez@g.hmc.edu
  12/10/2019
  shiftrows transformation modules
*/

/*
  Below is a module for the shiftrows transform on the
  AES encryption state matrix. Row i (from 0 to 3) if cyclically
  logical left-shifted by i bytes.

  Inputs:
    a[127:0]: state matrix

  Outputs:
    y[127:0]: shiftrows-transformed state matrix
*/
module shiftrows(input  logic [127:0] a,
                 output logic [127:0] y);

  assign { y[127:120], y[95:88], y[63:56], y[31:24]} = { a[127:120], a[95:88], a[63:56], a[31:24]};

  rotword #(1) rw0(
    { a[119:112], a[87:80], a[55:48], a[23:16]},
    { y[119:112], y[87:80], y[55:48], y[23:16]}
  );

  rotword #(2) rw1(
    { a[111:104], a[79:72], a[47:40], a[15:8]},
    { y[111:104], y[79:72], y[47:40], y[15:8]}
  );

  rotword #(3) rw2(
    { a[103:96], a[71:64], a[39:32], a[7:0]},
    { y[103:96], y[71:64], y[39:32], y[7:0]}
  );

endmodule

/*
  Below is a module to rotate a 32-bit word to the left
  by a parameterized number of bytes.

  Parameters:
    shift:   number of bytes cyclically shifted left

  Inputs:
    word[32:0]:   input word

  Outputs:
    rotated[7:0]: rotated word
*/
module rotword #(parameter shift = 1)
                (input  logic [31:0] word,
                 output logic [31:0] rotated);

  assign rotated = {word[(31 - 8*shift ):0], word[31:(32 - 8*shift)]};

endmodule