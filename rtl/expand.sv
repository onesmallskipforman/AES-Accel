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

  typedef enum logic {FWD, BWD} dirstatetype;
  statetype dirstate, nextdirstate;

  always_ff @(posedge clk)
    if (reset) begin
      state       <= S0;
      dirstate    <= FWD;
      lastBlock   <= 32'b0;
      rcon        <= 32'h01000000;
    end else begin
      state       <= nextstate;
      lastBlock   <= wBlock;
      rcon        <= nextrcon;
      dirstate    <= nextdirstate;
    end

  // next state logic
  always_comb
    if (dirstate == FWD)
      case(state)
        S0: if      (K == 128) nextstate = S1;
            else if (K == 256) nextstate = S2;
            else               nextstate = S3;
        S1: if      (K == 128) nextstate = S1;
            else if (K == 256) nextstate = S2;
            else               nextstate = S3;
        S2:                    nextstate = S1;
        S3:                    nextstate = S2;
        default:               nextstate = S0;
      endcase
    else /* dirstate == BWD */
      case(state)
        S0: if      (K == 128) nextstate = S1;
            else if (K == 256) nextstate = S2;
            else               nextstate = S3;
        S1: if      (K == 128) nextstate = S1;
            else               nextstate = S2;
        S2: if      (K == 256) nextstate = S1;
            else               nextstate = S3;
        S3:                    nextstate = S1;
        default:               nextstate = S0;
      endcase

  // next expansion direction logic
  always_comb
    case(dirstate)
      FWD: if (!predone) nextdirstate = FWD;
           else          nextdirstate = BWD;
      BWD:               nextdirstate = BWD;
      default:           nextdirstate = FWD;
    endcase

  // temp block decision logic
  always_comb
    if (dirstate == BWD) transform = lastBlock[31:0] ^ lastBlock[63:32];
    else begin           transform = lastBlock[31:0];

  // temp block logic
  rotate #(1, 4, 8) rw(transform, rotTemp);
  subword           sw(rotTemp, subTemp);

  assign rconTemp     = subTemp           ^ rcon;
  assign temp[127:96] = lastBlock[127:96] ^ rconTemp;

  genvar i;
  generate
    for (i = K-32; i > 0; i=i-32) begin: tempAssign
      // unique case for 256-bit expansion block
      if ( (K == 256) && (i == 128) ) begin
        always_comb
          if (dirstate == FWD)       subTransform  = temp[i+32-1:i];
          else /* dirstate == BWD */ subTransform  = lastBlock[i+32-1:i];
        subword so(subTransform, subOrgTemp);
        assign temp[i-1:i-32]  = lastBlock[i-1:i-32]  ^ subOrgTemp;
      end else begin
        always_comb
          if (dirstate == FWD)       temp[i-1:i-32]  = lastBlock[i-1:i-32]  ^ temp[i+32-1:i];
          else /* dirstate == BWD */ temp[i-1:i-32]  = lastBlock[i-1:i-32]  ^ lastBlock[i+32-1:i];
      end
    end
  endgenerate

  // next round constant logic
  galoismult        gm(rcon[31:24], rconFront);
  invgaloismult     ig(rcon[31:24], invrconFront);

  always_comb begin
    if       (dirstate == BWD)                       nextrcon = {invrconFront, 24'b0};
    else if ((dirstate == FWD) & (nextstate != BWD)) nextrcon = {rconFront, 24'b0};
    else                                             nextrcon = rcon;

  // next expansion block logic
  always_comb
    if      (state == S0)                   wBlock = key;
    else if ((state == S1) | (state == S3)) wBlock = temp;
    else                                    wBlock = lastBlock;

  // output logic
  always_comb
    case(state)
      S0:      roundKey = key[K-1: K-128];   // first four words of key
      S1:      roundKey = temp[K-1: K-128];  // first four words of temp XOR'ed with last expansion block
      S2:      roundKey = lastBlock[127:0];  // last four words of last key block
      S3:      roundKey = {lastBlock[63:0],
                           temp[K-1: K-64]}; // last two words of last expansion block, first two of current block
      default: roundKey = temp[K-1: K-128];
    endcase

endmodule
