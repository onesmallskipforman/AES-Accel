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

module aes_spi #(parameter K = 128, INV)
                (input  logic         sclk,
                 input  logic         mosi,
                 input  logic         done,
                 input  logic [127:0] translated,
                 output logic         miso,
                 output logic [K-1:0] key,
                 output logic [127:0] message,
                 output logic [7:0]   dirByte);

  logic         miso_delayed, wasdone;
  logic [127:0] translatedcaptured;

  // assert load
  // apply 256 sclks to shift in key and message, starting with message[0]
  // then deassert load, wait until done
  // then apply 128 sclks to shift out translated, starting with translated[0]
  always_ff @(posedge sclk)
    if (INV != 2) begin
      if (!wasdone)  {translatedcaptured, message, key} = {translated, message[126:0], key, mosi};
      else           {translatedcaptured, message, key} = {translatedcaptured[126:0], message, key, mosi};
     end else begin 
      if (!wasdone)  {translatedcaptured, dirByte, message, key} = {translated, dirByte[6:0], message, key, mosi};
      else           {translatedcaptured, dirByte, message, key} = {translatedcaptured[126:0], dirByte, message, key, mosi};
    end

  // miso should change on the negative edge of sclk
  always_ff @(negedge sclk) begin
      wasdone <= done;

      // the 126-th bit on the last sclk negedge will be the 127-th bit for
      // the next posedge, which is what we want passed to miso on that next tick
      miso_delayed <= translatedcaptured[126];
  end

  // when done is first asserted, shift out msb before clock edge
  assign miso = (done & !wasdone) ? translated[127] : miso_delayed;

endmodule
