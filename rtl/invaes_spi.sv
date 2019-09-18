/*
  Robert "Skipper" Gonzalez
  sgonzalez@g.hmc.edu
  12/10/2019
  Module for handling SPI communication between encryptor and master (rpi)

  Below is a module for managing SPI communication between the AES encryption
  hardware and a master sending messages to be encrypted. Pre-encryption, this
  module shifts in the key and message from the master with ticks of sclk. Post-
  encryption (done bit asserted), this module shift out bits of the encrypted
  message with ticks of sclk. Tricky cases are handled for when encryption is over
  and spi communication resumes (spi after done is first asserted).

  Inputs:
    sclk:                     spi master clock signal
    mosi:                     input from spi master
    done:                     done bit signalling encryption completed
    cyphertext[127:0]:        encrypted 128-bit message

  Outputs:
    miso:                     output to spi master
    key[127:0]:               128-bit encryption key
    plaintext[127:0]:         unecrpyted 128-bit message

  Internal Vars:
    wasdone:                   done bit from the last tick of sclk
    miso_delayed:              MSB of cyphertextcaptured from last clock tick
    cyphertextcaptured[127:0]: encrypted message bits shifted out to miso
*/

module invaes_spi(input  logic         sclk,
                  input  logic         mosi,
                  input  logic         done,
                  input  logic [127:0] cyphertext,
                  output logic         miso,
                  output logic [127:0] key, plaintext);

  logic         miso_delayed, wasdone;
  logic [127:0] cyphertextcaptured;

  // assert load
  // apply 256 sclks to shift in key and plaintext, starting with plaintext[0]
  // then deassert load, wait until done
  // then apply 128 sclks to shift out cyphertext, starting with cyphertext[0]
  always_ff @(posedge sclk)
      if (!wasdone)  {cyphertextcaptured, plaintext, key} = {cyphertext, plaintext[126:0], key, mosi};
      else           {cyphertextcaptured, plaintext, key} = {cyphertextcaptured[126:0], plaintext, key, mosi};

  // miso should change on the negative edge of sclk
  always_ff @(negedge sclk) begin
      wasdone = done;

      // the 126-th bit on the last sclk negedge will be the 127-th bit for
      // the next posedge, which is what we want passed to miso on that next tick
      miso_delayed = cyphertextcaptured[126];
  end

  // when done is first asserted, shift out msb before clock edge
  assign miso = (done & !wasdone) ? cyphertext[127] : miso_delayed;

endmodule
