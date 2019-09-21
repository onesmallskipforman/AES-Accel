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

module expand #(parameter K = 128)
               (input  logic          clk, reset,
                input  logic          predone,
                input  logic          done,
                input  logic [K-1:0]  key,
                output logic [127:0]  roundKey);

  logic [31:0]  rcon, nextrcon, transform, rotTemp, subTemp, rconTemp, subTransform, subOrgTemp;
  logic [K-1:0] lastBlock, temp, wBlock;
  logic [7:0]   rconFront, invrconFront;

  typedef enum logic [2:0] {START, S0, S1, S2, S3} statetype;
  statetype state, nextstate;

  typedef enum logic {FWD, BWD} dirstatetype;
  dirstatetype dirstate, nextdirstate;

  always_ff @(posedge clk)
    if (reset) begin
      state       <= START;
      dirstate    <= FWD;
      lastBlock   <= 32'b0;
      rcon        <= 32'h01000000;
    end else if (!done) begin
      state       <= nextstate;
      lastBlock   <= wBlock;
      rcon        <= nextrcon;
      dirstate    <= nextdirstate;
    end

  // next state logic
  always_comb
    if ((dirstate == FWD) & (nextdirstate != BWD))
      case(state)
        START:                 nextstate = S0;
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
        START:                 nextstate = S0;
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
    else                 transform = lastBlock[31:0];

  // temp block logic
  rotate #(1, 4, 8) rw(transform, rotTemp);
  subword           sw(rotTemp, subTemp);

  assign rconTemp     = subTemp           ^ rcon;
  assign temp[K-1:K-32] = lastBlock[K-1:K-32] ^ rconTemp;

  genvar i;
  generate
    for (i = K-32; i > 0; i=i-32) begin: tempAssign
      // unique case for 256-bit expansion block
      if ( (K == 256) && (i == 128) ) begin
        assign subTransform = (dirstate == FWD)? temp[i+32-1:i] : lastBlock[i+32-1:i];
        subword so(subTransform, subOrgTemp);
        assign temp[i-1:i-32]  = lastBlock[i-1:i-32]  ^ subOrgTemp;
      end else begin
        assign  temp[i-1:i-32] = (dirstate == FWD)? (lastBlock[i-1:i-32]  ^ temp[i+32-1:i]) : (lastBlock[i-1:i-32]  ^ lastBlock[i+32-1:i]);
      end
    end
  endgenerate

  // next round constant logic
  galoismult        gm(rcon[31:24], rconFront);
  invgaloismult     ig(rcon[31:24], invrconFront);

  always_comb
    if ( (dirstate == FWD) & (nextdirstate == BWD) )
      nextrcon = rcon;
    else if (dirstate == FWD)
      if ( ( (K == 128) & (state == S1) ) | (state == S1) | (state == S3)) nextrcon = {rconFront, 24'b0};
      else                               nextrcon = rcon;
    else
      if ( (K == 128) | (state == S1) | ( (K == 192) & (state == S2) ) ) nextrcon = {invrconFront, 24'b0}; // TODO
      else                               nextrcon = rcon;


  // next expansion block logic
  always_comb
    if ( (dirstate == FWD) & (nextdirstate == BWD) )
      wBlock = temp;
    else if (dirstate == FWD)
      if      (state == S0)                   wBlock = key;
      else if ((state == S1) | (state == S3)) wBlock = temp;
      else                                    wBlock = lastBlock;
    else
      if      (state == S0)                   wBlock = key;
      else if ( (K == 128) | (state == S2) | (state == S3)) wBlock = temp;
      else                                    wBlock = lastBlock;

  // output logic
  always_comb
    if ( (dirstate == FWD) )
      case(state)
        START:   roundKey = 0;
        S0:      roundKey = key[K-1: K-128];   // first four words of key
        S1:      roundKey = temp[K-1: K-128];  // first four words of temp XOR'ed with last expansion block
        S2:      roundKey = lastBlock[127:0];  // last four words of last key block
        S3:      roundKey = {lastBlock[63:0],
                             temp[K-1: K-64]}; // last two words of last expansion block, first two of current block
        default: roundKey = temp[K-1: K-128];
      endcase
    else
      case(state)
        START:   roundKey = 0;
        S0:      roundKey = key[K-1: K-128];   // first four words of key
        S1:      if (K == 128) roundKey = temp[K-1: K-128];  // first four words of temp XOR'ed with last expansion block
                 else          roundKey = lastBlock[K-1: K-128];
        S2:      roundKey = temp[127:0];  // last four words of last key block
        S3:      roundKey = {temp[63:0],
                             lastBlock[K-1: K-64]}; // last two words of last expansion block, first two of current block
        default: roundKey = temp[K-1: K-128];
      endcase
endmodule
