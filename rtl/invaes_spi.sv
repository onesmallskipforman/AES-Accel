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

module invaes_spi #(parameter K = 128)
                   (input  logic         sclk,
                   input  logic         mosi,
                   input  logic         done,
                   input  logic [127:0] plaintext,
                   output logic         miso,
                   output logic [K-1:0] key,
                   output logic [127:0] cyphertext);

  logic         miso_delayed, wasdone;
  logic [127:0] plaintextcaptured;

  // assert load
  // apply 256 sclks to shift in key and cyphertext, starting with cyphertext[0]
  // then deassert load, wait until done
  // then apply 128 sclks to shift out plaintext, starting with plaintext[0]
  always_ff @(posedge sclk)
      if (!wasdone)  {plaintextcaptured, cyphertext, key} = {plaintext, cyphertext[126:0], key, mosi};
      else           {plaintextcaptured, cyphertext, key} = {plaintextcaptured[126:0], cyphertext, key, mosi};

  // miso should change on the negative edge of sclk
  always_ff @(negedge sclk) begin
      wasdone = done;

      // the 126-th bit on the last sclk negedge will be the 127-th bit for
      // the next posedge, which is what we want passed to miso on that next tick
      miso_delayed = plaintextcaptured[126];
  end

  // when done is first asserted, shift out msb before clock edge
  assign miso = (done & !wasdone) ? plaintext[127] : miso_delayed;

endmodule
