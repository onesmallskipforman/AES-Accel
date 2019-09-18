/*
  Robert "Skipper" Gonzalez
  sgonzalez@g.hmc.edu
  12/10/2019
  AES 128-bit key expansion

  Below is a module that performs an inverse of the key expansion function
  for 128-bit AES encryption. This module runs 4 steps of the 44-step
  algorithm at a time, allowing for the decryption step to complete
  in 11 cycles.

  Inputs:
    clk:              sytem clock signal
    reset:            reset signal to restart cypher process
    done:             done bit signalling encryption completed
    invkey[127:0]:    the final 128-bit round key value of key expansion

  Outputs:
    iwBlock[127:0]:   block of Nk=4 words generated in current cycle of inverse key expansion

  Internal Variables:
    rcon[31:0]:        round constant word array for the first step of the current cycle
    rotTemp[31:0]:     rotWord transform applied to last cylce's wBlock
    subTemp[31:0]:     subWord transform applied to rotTemp
    rconTemp[31:0]:    XOR between subWord and rcon
    lastiBlock[127:0]: last word from the expansion block from the last cycle
    temp[127:0]:       temporary storage for iwBlock for cycles 2-10
    rconFront[7:0]:    First word in rcon
*/

module invkeyexpansion (input  logic          clk, reset,
                        input  logic          done,
                        input  logic [127:0]  invkey,
                        output logic [127:0]  iwBlock);

  logic [31:0]  rcon, nextrcon, rotTemp, subTemp, rconTemp;
  logic [127:0] lastBlock, temp;
  logic [7:0]   rconFront;

  typedef enum logic {S0, S1} statetype;
  statetype state, nextstate;

  always_ff @(posedge clk)
    if (reset) begin
      state        <= S0;
      lastiBlock   <= 32'b0;
      rcon         <= 32'h36000000;
    end else begin
      state        <= nextstate;
      lastiBlock   <= iwBlock;
      rcon         <= nextrcon;
    end

  always_comb
    case(state)
      S0:      nextstate = S1;
      S1:      nextstate = S1;
      default: nextstate = S0;
    endcase

  rotate #(1, 1, 8) rw(lastiBlock[31:0] ^ lastiBlock[63:32], rotTemp);
  subword           sw(rotTemp, subTemp);
  invgaloismult     gm(rcon[31:24], rconFront);

  always_comb begin
    rconTemp     = subTemp            ^ rcon;
    temp[127:96] = lastiBlock[127:96] ^ rconTemp;
    temp[95:64]  = lastiBlock[95:64]  ^ lastiBlock[127:96];
    temp[63:32]  = lastiBlock[63:32]  ^ lastiBlock[95:64];
    temp[31:0]   = lastiBlock[31:0]   ^ lastiBlock[63:32];
  end

  assign nextrcon = (state == S0)? rcon:{rconFront, 24'b0};
  assign iwBlock   = (state == S1)? temp:invkey;

endmodule
