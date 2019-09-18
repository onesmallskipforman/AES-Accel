/*
  Robert "Skipper" Gonzalez
  sgonzalez@g.hmc.edu
  12/10/2019
  AES 128-bit key expansion

  Below is a module that performs the keyexpansion function for K-bit AES
  encryption. This module runs 4 steps of the algorithm at a time,
  allowing 128-, 192-, and 128-bit encyption encryption to complete
  11 cycles, 13 cycles, and 15 cycles, respectively.

  Parameters:
    K:                        the length of the key

  Inputs:
    clk:              sytem clock signal
    reset:            reset signal to restart cypher process
    done:             done bit signalling encryption completed
    key[K-1:0]:       K-bit encryption key

  Outputs:
    roundKey[127:0]:    block of four words generated in current cycle of key expansion

  Internal Variables:
    wBlock[127:0]:    block of K words generated for the expanded key
    rcon[31:0]:       round constant word array for the first step of the current cycle
    rotTemp[31:0]:    rotWord transform applied to last cylce's wBlock
    subTemp[31:0]:    subWord transform applied to rotTemp
    subOrgTemp[31:0]: subWord transform applied to last cylce's wBlock
    finalTemp[31:0]:  final temp value to be XOR'ed with lastBlock[127:96]
    rconTemp[31:0]:   XOR between subWord and rcon
    lastBlock[127:0]: last word from the expansion block from the last cycle
    temp[127:0]:      temporary storage for wBlock for cycles 2-10
    rconFront[7:0]:   First word in rcon
*/

module keyexpansion #(parameter K = 128)
                     (input  logic          clk, reset,
                      input  logic          done,
                      input  logic [K-1:0]  key,
                      output logic [127:0]  roundKey);

  logic [31:0]  rcon, nextrcon, rotTemp, subTemp, rconTemp, subOrgTemp, finalTemp;
  logic [K-1:0] lastBlock, temp, wBlock;
  logic [7:0]   rconFront;

  typedef enum logic [1:0] {S0, S1, S2, S3} statetype;
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
      S0: if      (K == 128) nextstate = S1;
          else if (K == 256) nextstate = S3;
          else               nextstate = S4;
      S1: if      (K == 128) nextstate = S1;
          else if (K == 256) nextstate = S2;
          else               nextstate = S5;
      S2:                    nextstate = S1;
      S3:                    nextstate = S1;
      S4:                    nextstate = S1;
      S5:                    nextstate = S2;
      default:               nextstate = S0;
    endcase

  rotate #(1, 4, 8) rw(lastBlock[31:0], rotTemp);
  subword           sw(rotTemp, subTemp);
  galoismult        gm(rcon[31:24], rconFront);

  assign rconTemp       = subTemp             ^ rcon;
  assign temp[K-1:K-32] = lastBlock[K-1:K-32] ^ rconTemp;

  genvar i;
  generate
    for (i = K-32; i > 0; i=i-32) begin: tempAssign
      if ( (K == 256) && (i == 128) ) begin
        subword so(temp[i+32-1:i], subOrgTemp);
        assign temp[i-1:i-32]  = lastBlock[i-1:i-32]  ^ subOrgTemp;
      end else
        assign temp[i-1:i-32]  = lastBlock[i-1:i-32]  ^ temp[i+32-1:i];
      end
    end
  endgenerate

  always_comb
    case(state)
      S0:      roundKey = key[K-1: K-128];
      S1:      roundKey = temp[K-1: K-128];
      S2:      roundKey = temp[127:0];
      S3:      roundKey = key[127:0];
      S4:      roundKey = {key[63:0], temp[191:128]}; // TODO: reduce S4+S5 when you make synchronous
      S5:      roundKey = {lastBlock[63:0], temp[191:128]};
      default: roundKey = temp[K-1: K-128];
    endcase

  always_comb
    if      (state == S0) wBlock = key;
    else if (state == S1) wBlock = temp;
    else                  wBlock = lastBlock;

  assign nextrcon = (state != S1)? rcon:{rconFront, 24'b0};

endmodule
