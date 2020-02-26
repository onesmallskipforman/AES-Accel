/*
  Robert "Skipper" Gonzalez
  sgonzalez@g.hmc.edu
  12/10/2019
  top-level module containing SPI coms and AES core

  Below is the top level module for an AES hardware accelerator. This module
  is designed to recieve key and message from a rasberry pi over SPI
  communication, and then perform AES encryption. 128-, 192-, and 256-bit AES
  Encryptions are supported.

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
    done:   done bit signalling encryption completed

  Internal Variables:
    key[K-1:0]:        K-bit encryption key
    message[K-1:0]:  unecrpyted K-bit message
    translated[K-1:0]: encrypted K-bit message
*/

module aes #(parameter K = 128, INV = 2)
            (input  logic clk,
             input  logic r_sclk,
             input  logic r_mosi,
             input  logic r_ce,
             output logic r_miso,
             output logic done);

  // generate block to filter invalid key sizes
  generate
    if ( (K != 128) & (K != 192) & (K != 256) ) begin
      // $error("** Illegal Condition ** Key size: %d Invalid for AES Encryption. Valid Key sizes: 128, 192, and 256", K);
      illegal_keylength_condition_triggered non_existing_module();
    end
    if ( (INV != 1) & (INV != 0) & (INV != 2) ) begin
      // $error("** Illegal Condition ** Key size: %d Invalid for AES Encryption. Valid Key sizes: 128, 192, and 256", K);
      illegal_keylength_condition_triggered non_existing_module();
    end
  endgenerate

  logic [K-1:0] key;
  logic [127:0] message, translated;
  logic [7:0] dirByte;
  logic ce_imd, ce;

  aes_spi  #(K, INV) spi(r_sclk, r_mosi, done, translated, r_miso, key, message, dirByte);
  aes_core #(K, INV) core(clk, ce, key, message, dirByte[0], done, translated);

  // synchronize reset
  always_ff @(posedge clk) begin
    ce_imd <= r_ce;
    ce     <= ce_imd;
  end

endmodule
