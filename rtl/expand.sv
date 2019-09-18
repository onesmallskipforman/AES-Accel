/*
  Robert "Skipper" Gonzalez
  sgonzalez@g.hmc.edu
  12/10/2019
  AES 128-bit key expansion

  Below is a module that performs forward and reverse key expansion
  for K-bit AES decryption. This module runs 4 steps of the algorithm at a time,
  allowing 128-, 192-, and 128-bit encyption expansion to complete
  11 cycles, 13 cycles, and 15 cycles, respectively.

  Parameters:
    K:                 the length of the key

  Inputs:
    clk:               sytem clock signal
    reset:             reset signal to restart cypher process
    predone:           done bit signalling forward key expansion complete
    key[K-1:0]:        K-bit encryption key

  Outputs:
    wBlock[127:0]:     block of four words generated in current cycle of key expansion

  Internal Variables:
    rcon[31:0]:        round constant word array for the first step of the current cycle
    nextrcon[31:0]:    round constant word array for the first step of the next cycle
    transform[31:0]:   word to be transformed by rotWord, subWord, and XOR with rcon
    rotTemp[31:0]:     rotWord transform applied to transform
    subTemp[31:0]:     subWord transform applied to rotTemp
    rconTemp[31:0]:    XOR between subWord and rcon
    lastBlock[127:0]:  last word from the expansion block from the last cycle
    temp[127:0]:       temporary storage for wBlock for cycles 2-10
    rconFront[7:0]:    First word in rcon after multiplication with x in GF(8)
    invrconFront[7:0]: First word in rcon after multiplication with x^-1 in GF(8)
*/

module expand (input  logic          clk, reset,
               input  logic          predone,
               input  logic [127:0]  key,
               output logic [127:0]  wBlock);

  logic [31:0]  rcon, nextrcon, transform, rotTemp, subTemp, rconTemp;
  logic [127:0] lastBlock, temp;
  logic [7:0]   rconFront, invrconFront;

  typedef enum logic [1:0] {S0, S1, S2} statetype;
  statetype state, nextstate;

  always_ff @(posedge clk)
    if (reset) begin
      state       <= S0;
      lastBlock   <= 32'b0;
      rcon        <= 32'h01000000;
    end else begin
      state       <= nextstate;
      lastBlock   <= wBlock;
      rcon        <= nextrcon;
    end

  always_comb
    case(state)
      S0:                    nextstate = S1;
      S1:      if (!predone) nextstate = S1;
               else          nextstate = S2;
      S2:                    nextstate = S2;
      default:               nextstate = S0;
    endcase

  always_comb
    if (state == S2) transform = lastBlock[31:0] ^ lastBlock[63:32];
    else             transform = lastBlock[31:0];

  rotate #(1, 4, 8) rw(transform, rotTemp);
  subword           sw(rotTemp, subTemp);
  galoismult        gm(rcon[31:24], rconFront);
  invgaloismult     ig(rcon[31:24], invrconFront);

  always_comb begin
    rconTemp     = subTemp           ^ rcon;
    temp[127:96] = lastBlock[127:96] ^ rconTemp;
    if (state == S1) begin
      temp[95:64]  = lastBlock[95:64]  ^ temp[127:96];
      temp[63:32]  = lastBlock[63:32]  ^ temp[95:64];
      temp[31:0]   = lastBlock[31:0]   ^ temp[63:32];
    end else if (state == S2) begin
      temp[95:64]  = lastBlock[95:64]  ^ lastBlock[127:96];
      temp[63:32]  = lastBlock[63:32]  ^ lastBlock[95:64];
      temp[31:0]   = lastBlock[31:0]   ^ lastBlock[63:32];
    end else begin
      temp[95:0] = 96'b0;
    end

    if (state == S2) 
      nextrcon = {invrconFront, 24'b0};
    else if ((state == S1) & (nextstate != S2))                     
      nextrcon = {rconFront, 24'b0};
    else                                       
      nextrcon = rcon;
  end

  assign wBlock   = (state == S0)? key:temp;

endmodule