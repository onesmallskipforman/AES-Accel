/*
  Robert "Skipper" Gonzalez
  sgonzalez@g.hmc.edu
  12/10/2019
  top-level module containing SPI coms and AES core

  Below is the top level module for an AES hardware accelerator. This module
  is designed to recieve key and cyphertext from a rasberry pi over SPI
  communication, and then perform AES decryption. 128-, 192-, and 256-bit AES
  Decryptions are supported.

  Parameters:
    K:      the length of the key

  Inputs:
    clk:    sytem clock signal
    reset:  reset signal
    r_sclk: pi (master) spi clock
    r_mosi: pi mosi
    r_ce:   chip enable (or load). high during conversion

  Outputs:
    r_miso: pi miso
    done:   done bit signalling decryption completed

  Internal Variables:
    key[K-1:0]:        K-bit encryption key
    plaintext[127:0]:  unecrpyted 128-bit message
    cyphertext[127:0]: encrypted 128-bit message
*/

module invaes #(parameter K = 128)
               (input  logic clk, reset,
                input  logic r_sclk,
                input  logic r_mosi,
                input  logic r_ce,
                output logic r_miso,
                output logic done);

  // generate block to filter invalid key sizes
  generate
    if ( (K != 128) & (K != 192) & (K != 256) ) begin
      //$error("** Illegal Condition ** Key size: %d Invalid for AES Encryption. Valid Key sizes: 128, 192, and 256", K);
      illegal_keylength_condition_triggered non_existing_module();
    end
  endgenerate

  logic [K-1:0] key;
  logic [127:0] plaintext, cyphertext;
  logic [7:0] dirByte;

  invaes_spi  #(K) spi(r_sclk, r_mosi, done, plaintext, r_miso, key, cyphertext, dirByte);
  invaes_core #(K) core(clk, reset, r_ce, key, cyphertext, dirByte[0], done, plaintext);

endmodule
