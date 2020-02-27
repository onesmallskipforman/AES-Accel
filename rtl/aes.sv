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

module aes #(parameter K = 192, INV = 1)
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

  logic [K-1:0] key_a, key_i, key;
  logic [127:0] message_a, message_i, message, translated;
  logic [7:0] dirByte_a, dirByte_i, dirByte;
  logic ce_i, ce, was_ce, was_was_ce, reset_core;

  // assert load
  // apply 256 sclks to shift in key and message, starting with message[0]
  // then deassert load, wait until done
  // then apply 128 sclks to shift out translated, starting with translated[0]
  generate
    if (INV == 2) spi_slave #(K + 128 + 8, 128) spi(r_sclk, r_mosi, done, translated, r_miso, {dirByte, message, key});
    else          spi_slave #(K + 128, 128)     spi(r_sclk, r_mosi, done, translated, r_miso, {message, key});
  endgenerate

  aes_core #(K, INV) core(clk, r_ce, key, message, dirByte[0], done, translated);

  // synchronizer options
  // always_ff @(posedge clk) begin
  //   chip enable synchronization
  //   ce_i <= r_ce;
  //   ce   <= ce_i;
  //   {key_i, message_i, dirByte_i} <= {key_a, message_a, dirByte_a};
    
  //   unconditional synchronization
  //   {key, message, dirByte} <= {key_i, message_i, dirByte_i};
   
  //   conditional synchronization
  //   if (ce) {key, message, dirByte} <= {key_i, message_i, dirByte_i};
  // end
  // aes_spi  #(K, INV) spi(r_sclk, r_mosi, done, translated, r_miso, key_a, message_a, dirByte_a);
  // aes_core #(K, INV) core(clk, ce, key, message, dirByte[0], done, translated);

endmodule
