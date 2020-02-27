//==============================================================================
// testbench
//   Tests AES with cases from FIPS-197 appendix
//==============================================================================

module testbench();

  // number of key bits
  parameter K = 128, INV = 2;

  logic clk, load, done, sck, sdi, sdo;
  logic [K-1:0] key;
  logic [127:0] plaintext, cyphertext, expected, message, translated;
  logic [K+128+8-1:0] comb;
  logic [9:0] i;
  logic [7:0] dirByte;

  // device under test
  aes #(K, INV) dut(clk, sck, sdi, load, sdo, done);

  assign dirByte = 8'hFF;

  initial begin
    if (K == 128) begin
      // Test case from FIPS-197 Appendix A.1, B
      key        <= 128'h2B7E151628AED2A6ABF7158809CF4F3C;
      plaintext  <= 128'h3243F6A8885A308D313198A2E0370734;
      cyphertext <= 128'h3925841D02DC09FBDC118597196A0B32;
      // Alternate test case from Appendix C.1
      // key       <= 128'h000102030405060708090A0B0C0D0E0F;
      // plaintext <= 128'h00112233445566778899AABBCCDDEEFF;
      // cyphertext  <= 128'h69C4E0D86A7B0430D8CDB78070B4C55A;
    end else if (K == 192) begin
      // 192-bit test case from Appendix C.2
      cyphertext <= 128'hdda97ca4864cdfe06eaf70a0ec0d7191;
      plaintext  <= 128'h00112233445566778899aabbccddeeff;
      key        <= 192'h000102030405060708090a0b0c0d0e0f1011121314151617;
      // key <= 192'h8e73b0f7da0e6452c810f32b809079e562f8ead2522c6b7b;
    end else begin
      // 256-bit test case from Appendix C.3
      cyphertext <= 128'h8ea2b7ca516745bfeafc49904b496089;
      plaintext  <= 128'h00112233445566778899aabbccddeeff;
      key        <= 256'h000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f;
      // key <= 256'h603deb1015ca71be2b73aef0857d77811f352c073b6108d72d9810a30914dff4;
    end
  end

  // generate clock and load signals
  initial
    forever begin
      clk = 1'b0; #5;
      clk = 1'b1; #5;
    end

  initial begin
    i = 0;
    load = 1'b1;
  end

  assign {message, expected} = ((INV == 0) | ((INV == 2) & (dirByte == 8'h00)))?
    {plaintext, cyphertext} : {cyphertext, plaintext};

  assign comb = {dirByte, message, key};
  parameter total = (INV != 2)? K + 128 : K + 128 + 8;

  // shift in test vectors, wait until done, and shift out result
  always @(posedge clk) begin
    if (i == total) load = 1'b0;
    if (i<total) begin
      // load = 1'b1;
      #1; sdi = comb[total-1-i];
      #1; sck = 1; #5; sck = 0;
      i = i + 1;
    end else if (done && i < (total + 128) ) begin
      #1; sck = 1;
      #1; translated[total+128-1-i] = sdo;
      #4; sck = 0;
      i = i + 1;
    end else if (i == total + 128) begin
      if (translated == expected)
        $display("Testbench ran successfully");
      else
        $display("Error: translated = %h, expected %h", translated, expected);
      $stop();
    end
  end

endmodule
