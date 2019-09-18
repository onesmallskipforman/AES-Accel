/*
  Robert "Skipper" Gonzalez
  sgonzalez@g.hmc.edu
  12/10/2019
  top-level module containing SPI coms and AES core

  Below is the top level module for an AES hardware accelerator. This module
  is designed to recieve key and plaintext from a rasberry pi over SPI
  communication, and then perform AES encryption. Currently only 128-bit
  AES Encryption is supported.

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
    key[127:0]:        128-bit encryption key
    plaintext[127:0]:  unecrpyted 128-bit message
    cyphertext[127:0]: encrypted 128-bit message
*/

module aes(input  logic clk, reset,
           input  logic r_sclk,
           input  logic r_mosi,
           input  logic r_ce,
           output logic r_miso,
           output logic done);

  logic [127:0] key, plaintext, cyphertext;

  aes_spi  spi(r_sclk, r_mosi, done, cyphertext, r_miso, key, plaintext);
  aes_core core(clk, reset, r_ce, key, plaintext, done, cyphertext);

endmodule
