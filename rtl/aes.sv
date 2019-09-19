/*
  Robert "Skipper" Gonzalez
  sgonzalez@g.hmc.edu
  12/10/2019
  top-level module containing SPI coms and AES core

  Below is the top level module for an AES hardware accelerator. This module
  is designed to recieve key and plaintext from a rasberry pi over SPI
  communication, and then perform AES encryption. Currently only 128-bit and
  256-bit AES Encryption is supported.

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
    plaintext[K-1:0]:  unecrpyted K-bit message
    cyphertext[K-1:0]: encrypted K-bit message
*/

module aes #(parameter K = 128)
            (input  logic clk, reset,
             input  logic r_sclk,
             input  logic r_mosi,
             input  logic r_ce,
             output logic r_miso,
             output logic done);

  logic [K-1:0] key;
  logic [127:0] plaintext, cyphertext;

  aes_spi  #(K) spi(r_sclk, r_mosi, done, cyphertext, r_miso, key, plaintext);
  aes_core #(K)  core(clk, reset, r_ce, key, plaintext, done, cyphertext);

endmodule
