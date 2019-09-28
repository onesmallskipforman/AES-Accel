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
    plaintext[127:0]:         decrypted 128-bit message

  Outputs:
    miso:                     output to spi master
    key[K:0]:                 128-bit encryption key
    cyphertext[127:0]:        encrpyted 128-bit message

  Internal Vars:
    wasdone:                   done bit from the last tick of sclk
    miso_delayed:              MSB of plaintextcaptured from last clock tick
    plaintextcaptured[127:0]:  decrypted message bits shifted out to miso
*/

module spi_slave #(parameter N)
                  (input  logic         clk,
                   input  logic         sclk,
                   input  logic         ce,
                   input  logic         mosi,
                   input  logic [N-1:0] full_miso,
                   output logic         miso,
                   output logic [N-1:0] full_mosi,
                   output logic         spi_done);

  logic         miso_delayed, was_ce, nce_i;
  logic [N-1:0] shift_miso;

  // synchronizers for spi completion and mosi
  always_ff @(posedge clk) begin
    nce_i       <= !ce;
    spi_done    <= nce_i;
    full_mosi_i <= full_mosi_a;
    full_mosi   <= full_mosi_i;
  end

  // asynchronous was_ce reset for start of spi
  always_ff @(posedge ce)
    was_ce <= 1'b0;

  // assert load
  always_ff @(posedge sclk)
    if (!was_ce) {shift_miso, full_mosi_i, key} = {full_miso, full_mosi_i[N-2:0], mosi};
    else         {shift_miso, full_mosi_i, key} = {shift_miso[N-2:0], full_mosi_i, mosi};

  // miso should change on the negative edge of sclk
  always_ff @(negedge sclk) begin
    was_ce = ce;
    miso_delayed = shift_miso[N-2];
  end

  // when done is first asserted, shift out msb before clock edge
  assign miso = (ce & !was_ce) ? full_miso[N-1] : miso_delayed;

endmodule
