/*
  Robert "Skipper" Gonzalez
  sgonzalez@g.hmc.edu
  12/10/2019
  Module for handling SPI communication between encryptor and master (rpi)

  Below is a module for managing SPI communication between the AES decryption
  hardware and a master sending messages to be encrypted. Pre-encryption, this
  module shifts in the key and message from the master with ticks of sclk. Post-
  encryption (done bit asserted), this module shift out bits of the encrypted
  message with ticks of sclk. Tricky cases are handled for when decryption is over
  and spi communication resumes (spi after done is first asserted).

  Parameters:
    K:                        the length of the key

  Inputs:
    sclk:                     spi master clock signal
    mosi:                     input from spi master
    done:                     done bit signalling encryption completed
    translated[127:0]:         decrypted 128-bit message

  Outputs:
    miso:                     output to spi master
    key[K:0]:               128-bit encryption key
    message[127:0]:        encrpyted 128-bit message

  Internal Vars:
    wasdone:                   done bit from the last tick of sclk
    miso_delayed:              MSB of translatedcaptured from last clock tick
    translatedcaptured[127:0]:  decrypted message bits shifted out to miso
*/

module spi_slave #(parameter N, M = N)
                  (input  logic         sclk,
                   input  logic         mosi,
                   input  logic         done,
                   input  logic [M-1:0] full_miso,
                   output logic         miso,
                   output logic [N-1:0] full_mosi);

  logic         miso_delayed, wasdone;
  logic [M-1:0] full_miso_captured;

  always_ff @(posedge sclk)
    if (!wasdone)  {full_miso_captured, full_mosi} = {full_miso, full_mosi[N-2:0], mosi};
    else           {full_miso_captured, full_mosi} = {full_miso_captured[M-2:0], full_mosi, mosi};

  // miso should change on the negative edge of sclk
  // the (M-2)-th bit on the last sclk negedge will be the (M-1)-th bit for
  // the next posedge, which is what we want passed to miso on that next tick
  always_ff @(negedge sclk) begin
    wasdone      <= done;
    miso_delayed <= full_miso_captured[M-2];
  end

  // when done is first asserted, shift out msb before clock edge
  assign miso = (done & !wasdone) ? full_miso[M-1] : miso_delayed;

endmodule
