





/////////////////////////////////////////////
// testbench
//   Tests AES with cases from FIPS-197 appendix
/////////////////////////////////////////////

module testbench();

  // number of key bits
  parameter K = 256;

  parameter inv = 1;

  logic clk, reset, load, done, sck, sdi, sdo;
  logic [K-1:0] key;
  logic [127:0] plaintext, cyphertext, expected;
  logic [K+128-1:0] comb;
  logic [9:0] i;

  // device under test
  aes #(K) dut(clk, reset, sck, sdi, load, sdo, done);

  // test case
  initial begin
    if (!inv)
      if (K == 128) begin

        // Test case from FIPS-197 Appendix A.1, B
        key       <= 128'h2B7E151628AED2A6ABF7158809CF4F3C;
        plaintext <= 128'h3243F6A8885A308D313198A2E0370734;
        expected  <= 128'h3925841D02DC09FBDC118597196A0B32;

        // Alternate test case from Appendix C.1
        // key       <= 128'h000102030405060708090A0B0C0D0E0F;
        // plaintext <= 128'h00112233445566778899AABBCCDDEEFF;
        // expected  <= 128'h69C4E0D86A7B0430D8CDB78070B4C55A;

      end else if (K == 192) begin

        // 192-bit test case from Appendix C.2
        expected       <= 128'hdda97ca4864cdfe06eaf70a0ec0d7191;
        plaintext <= 128'h00112233445566778899aabbccddeeff;
        key  <= 192'h000102030405060708090a0b0c0d0e0f1011121314151617;

      end else begin

        // 256-bit test case from Appendix C.3
        expected       <= 128'h8ea2b7ca516745bfeafc49904b496089;
        plaintext <= 128'h00112233445566778899aabbccddeeff;
        key  <= 256'h000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f;
        // key <= 256'h603deb1015ca71be2b73aef0857d77811f352c073b6108d72d9810a30914dff4;
      end
    else
      if (K == 128) begin
        // Test case from FIPS-197 Appendix A.1, B
        key       <= 128'h2B7E151628AED2A6ABF7158809CF4F3C;
        expected <= 128'h3243F6A8885A308D313198A2E0370734;
        plaintext  <= 128'h3925841D02DC09FBDC118597196A0B32;
      end else if (K == 192) begin
        // 192-bit test case from Appendix C.2
        plaintext <= 128'hdda97ca4864cdfe06eaf70a0ec0d7191;
        expected <= 128'h00112233445566778899aabbccddeeff;
        key  <= 192'h000102030405060708090a0b0c0d0e0f1011121314151617;
      end else begin
        // 256-bit test case from Appendix C.3
        plaintext       <= 128'h8ea2b7ca516745bfeafc49904b496089;
        expected <= 128'h00112233445566778899aabbccddeeff;
        key  <= 256'h000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f;
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
    reset = 1'b1; #1; reset = 1'b0;
    i = 0;
    load = 1'b0; #10; load = 1'b1;
  end

  assign comb = {plaintext, key};

  parameter total = K + 128;

  // shift in test vectors, wait until done, and shift out result
  always @(posedge clk) begin
    if (i == total) load = 1'b0;
    if (i<total) begin
      #1; sdi = comb[total-1-i];
      #1; sck = 1; #5; sck = 0;
      i = i + 1;
    end else if (done && i < (total + 128) ) begin
      #1; sck = 1;
      #1; cyphertext[total+128-1-i] = sdo;
      #4; sck = 0;
      i = i + 1;
    end else if (i == total + 128) begin
          if (cyphertext == expected)
              $display("Testbench ran successfully");
          else $display("Error: cyphertext = %h, expected %h",
              cyphertext, expected);
          $stop();
    end
  end

endmodule


/////////////////////////////////////////////
// testbench
//   Tests AES with cases from FIPS-197 appendix
/////////////////////////////////////////////

// module testbench();

//   // number of key bits
//   parameter K = 128;
//   parameter logic [7:0] dirByte = 8'b0; 

//   logic clk, reset, load, done, sck, sdi, sdo;
//   logic [K-1:0] key;
//   logic [127:0] plaintext, cyphertext, expected;
//   logic [K+128+8-1:0] comb;
//   logic [9:0] i;
  
//   // device under test
//   invaes #(K) dut(clk, reset, sck, sdi, load, sdo, done);

//   // test case
//   initial begin
//     if (dirByte)
//       if (K == 128) begin         
//         // Test case from FIPS-197 Appendix A.1, B
//         cyphertext <= 128'h3925841D02DC09FBDC118597196A0B32;
//         expected   <= 128'h3243F6A8885A308D313198A2E0370734;
//         key        <= 128'h2B7E151628AED2A6ABF7158809CF4F3C;
//       end else if (K == 192) begin 
//         // 192-bit test case from Appendix C.2
//         cyphertext <= 128'hdda97ca4864cdfe06eaf70a0ec0d7191;
//         expected   <= 128'h00112233445566778899aabbccddeeff;
//         key        <= 192'h000102030405060708090a0b0c0d0e0f1011121314151617;
//       end else begin               
//         // 256-bit test case from Appendix C.3
//         cyphertext <= 128'h8ea2b7ca516745bfeafc49904b496089;
//         expected   <= 128'h00112233445566778899aabbccddeeff;
//         key        <= 256'h000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f;
//       end
//     else // TODO: this is plaintext, not cyphertext. Fix variable names
//       if (K == 128) begin
//         // Test case from FIPS-197 Appendix A.1, B
//         key       <= 128'h2B7E151628AED2A6ABF7158809CF4F3C;
//         cyphertext <= 128'h3243F6A8885A308D313198A2E0370734;
//         expected  <= 128'h3925841D02DC09FBDC118597196A0B32;
//       end else if (K == 192) begin
//         // 192-bit test case from Appendix C.2
//         expected       <= 128'hdda97ca4864cdfe06eaf70a0ec0d7191;
//         cyphertext <= 128'h00112233445566778899aabbccddeeff;
//         key  <= 192'h000102030405060708090a0b0c0d0e0f1011121314151617;
//       end else begin
//         // 256-bit test case from Appendix C.3
//         expected       <= 128'h8ea2b7ca516745bfeafc49904b496089;
//         cyphertext <= 128'h00112233445566778899aabbccddeeff;
//         key  <= 256'h000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f;
//       end
//   end

//   // Alternate test case from Appendix C.1
//   // key       <= 128'h000102030405060708090A0B0C0D0E0F;
//   // expected <= 128'h00112233445566778899AABBCCDDEEFF;
//   // cyphertext  <= 128'h69C4E0D86A7B0430D8CDB78070B4C55A;

//   // always @(key)
//   //   $display("cyphertext = %h, key %h", cyphertext, key);

//   // generate clock and load signals
//   initial
//     forever begin
//       clk = 1'b0; #5;
//       clk = 1'b1; #5;
//     end

//   initial begin
//     reset = 1'b1; #1; reset = 1'b0;
//     i = 0;
//     load = 1'b0; #10; load = 1'b1;
//   end

//   assign comb = {cyphertext, key, dirByte};

//   parameter total = K + 128 + 8;

//   // shift in test vectors, wait until done, and shift out result
//   always @(posedge clk) begin
//     if (i == total) load = 1'b0;
//     if (i<total) begin
//       #1; sdi = comb[total-1-i];
//       #1; sck = 1; #5; sck = 0;
//       i = i + 1;
//     end else if (done && i < (total + 128) ) begin
//       #1; sck = 1;
//       #1; plaintext[total+128-1-i] = sdo;
//       #4; sck = 0;
//       i = i + 1;
//     end else if (i == total + 128) begin
//           if (plaintext == expected)
//               $display("Testbench ran successfully");
//           else $display("Error: plaintext = %h, expected %h",
//               plaintext, expected);
//           $stop();
//     end
//   end

// endmodule
