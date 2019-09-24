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
    done1:             done bit signalling forward key expansion complete
    key[K-1:0]:        K-bit encryption key

  Outputs:
    nextBlock[127:0]:     block of four words generated in current cycle of key expansion

  Internal Variables:
    rcon[31:0]:        round constant word array for the first step of the current cycle
    nextrcon[31:0]:    round constant word array for the first step of the next cycle
    transform[31:0]:   word to be transformed by rotWord, subWord, and XOR with rcon
    rotTemp[31:0]:     rotWord transform applied to transform
    subTemp[31:0]:     subWord transform applied to rotTemp
    rconTemp[31:0]:    XOR between subWord and rcon
    block[127:0]:      last word from the expansion block from the last cycle
    temp[127:0]:       temporary storage for nextBlock for cycles 2-10
    rconFront[7:0]:    First word in rcon after multiplication with x in GF(8)
    invrconFront[7:0]: First word in rcon after multiplication with x^-1 in GF(8)
*/

// module expand #(parameter K = 128)
//                (input  logic          clk, reset,
//                 input  logic          done1,
//                 input  logic          done2,
//                 input  logic [K-1:0]  key,
//                 output logic [127:0]  roundKey);

//   logic [31:0]  rcon, nextrcon, transform, rotTemp, subTemp, rconTemp, subTransform, subOrgTemp;
//   logic [K-1:0] block, temp, nextBlock;
//   logic [7:0]   rconFront, invrconFront;
//   logic         wasdone1, pivot;

//   typedef enum logic [1:0] {S0, S1, S2, S3} statetype;
//   statetype state, nextstate;

//   typedef enum logic {FWD, BWD} dirstatetype;
//   dirstatetype dirstate, nextdirstate;

//   always_ff @(posedge clk)
//     if (reset) begin
//       state       <= S0;
//       block       <= 32'b0;
//       rcon        <= 32'h8d000000;
//       wasdone1    <= 1'b0;
//     end else if (!done2) begin
//       state       <= nextstate;
//       block       <= nextBlock;
//       rcon        <= nextrcon;
//       wasdone1    <= done1;
//     end

//   assign pivot = (done1 & !wasdone1);

//   // next state logic
//   always_comb
//     if (pivot)                nextstate = S1;
//     else case(state)
//       S0:                     nextstate = S1;
//       S1: if      (K == 128)  nextstate = S1;
//           else if (K == 256)  nextstate = S2;
//           else                nextstate = S3;
//       S2:                     nextstate = S1;
//       S3:                     nextstate = S2;
//       default:                nextstate = S0;
//     endcase

//   // next round constant (rcon for current temp transform) logic
//   galoismult    gm(rcon[31:24], rconFront);
//   invgaloismult ig(rcon[31:24], invrconFront);

//   always_comb
//     if ((state == S0) | ((state == S1) & (K != 128)) | pivot) nextrcon = rcon;
//     else if (done1)                                           nextrcon = {invrconFront, 24'b0};
//     else                                                      nextrcon = {rconFront, 24'b0};


//   // temp block logic
//   assign transform = (done1)? (block[31:0]^block[63:32]) : block[31:0];
//   rotate #(1, 4, 8) rw(transform, rotTemp);
//   subword           sw(rotTemp, subTemp);
//   assign rconTemp       = subTemp         ^ nextrcon;
//   assign temp[K-1:K-32] = block[K-1:K-32] ^ rconTemp;

//   genvar i;
//   generate
//     for (i = K-32; i > 0; i=i-32) begin: tempAssign
//       // unique case for 256-bit expansion block
//       if ( (K == 256) && (i == 128) ) begin
//         assign subTransform = (!done1)? temp[i+32-1:i] : block[i+32-1:i];
//         subword so(subTransform, subOrgTemp);
//         assign temp[i-1:i-32]  = block[i-1:i-32]^subOrgTemp;
//       end else begin
//         assign temp[i-1:i-32] = (!done1)? (block[i-1:i-32]^temp[i+32-1:i]) : (block[i-1:i-32]^block[i+32-1:i]);
//       end
//     end
//   endgenerate

//   // next expansion block logic
//   always_comb
//     if       (state == S0)                        nextBlock = key;
//     else if ((K != 128) & (state == S1) & !pivot) nextBlock = block;
//     else                                          nextBlock = temp;

//   // output logic
//   always_comb
//     case(state)
//       S0: roundKey = 32'b0;
//       S1: roundKey = (!wasdone1)? block[K-1: K-128]             : block[127:0];
//       S2: roundKey = (!done1)?    block[127:0]                  : block[K-1: K-128];
//       S3: roundKey = (!done1)?   {block[63:0], temp[K-1: K-64]} : {temp[63:0], block[K-1: K-64]};
//       default: roundKey = 32'b0;
//     endcase

// endmodule


module expand #(parameter K = 128)
               (input  logic          clk, reset,
                input  logic          done1,
                input  logic          done2,
                input  logic [K-1:0]  key,
                output logic [127:0]  roundKey);

  logic [31:0]  rcon, nextrcon, transform, rotTemp, subTemp, rconTemp, tosub;
  logic [K-1:0] block, temp, nextBlock;
  logic [7:0]   rconFront, invrconFront;
  logic         wasdone1, pivot;

  typedef enum logic [1:0] {S0, S1, S2, S3} statetype;
  statetype state, nextstate;

  always_ff @(posedge clk)
    if (reset) begin
      state       <= S0;
      block       <= 32'b0;
      rcon        <= 32'h8d000000;
      wasdone1    <= 1'b0;
    end else if (!done2) begin
      state       <= nextstate;
      block       <= nextBlock;
      rcon        <= nextrcon;
      wasdone1    <= done1;
    end

  assign pivot = (done1 & !wasdone1);

  // next state logic
  always_comb
    if (pivot & (K == 192))   nextstate = S2;
    else case(state)
      S0:                     nextstate = S1;
      S1: if      (K == 128)  nextstate = S1;
          else if (K == 256)  nextstate = S2;
          else                nextstate = S3;
      S2:                     nextstate = S1;
      S3:                     nextstate = S2;
      default:                nextstate = S0;
    endcase

  // next round constant (rcon for current temp transform) logic
  galoismult    gm(rcon[31:24], rconFront);
  invgaloismult ig(rcon[31:24], invrconFront);

  always_comb
    if (pivot & (K != 256)) nextrcon = {rconFront, 24'b0};
    else if ((state == S0) | ((state == S1) & (K == 192)) | ((state == S2) & (K == 256)) | pivot) nextrcon = rcon;
    else if (done1)                                           nextrcon = {invrconFront, 24'b0};
    else                                                      nextrcon = {rconFront, 24'b0};

  // temp block logic
  assign transform = (done1 & (K != 256))? (block[31:0]^block[63:32]) : block[31:0];
  rotate #(1, 4, 8) rw(transform, rotTemp);

  always_comb
    if (K == 256)
      if      ((state == S2) & (!done1)) tosub = block[128+32-1:128];
      else if ((state == S1) & (done1))  tosub = block[128+32-1:128];
      else tosub = rotTemp;
    else 
      tosub = rotTemp;

  subword sw(tosub, subTemp);
  assign rconTemp       = subTemp         ^ nextrcon;
  assign temp[K-1:K-32] = block[K-1:K-32] ^ rconTemp;

  genvar i;
  generate
    for (i = K-32; i > 0; i=i-32) begin: tempAssign
      // unique case for 256-bit expansion block
      if ( (K == 256) && (i == 128) ) begin
        assign temp[i-1:i-32]  = block[i-1:i-32]^subTemp;
      end else begin
        assign temp[i-1:i-32] = (!done1)? (block[i-1:i-32]^temp[i+32-1:i]) : (block[i-1:i-32]^block[i+32-1:i]);
      end
    end
  endgenerate

  // next expansion block logic
  always_comb
    if                    (state == S0)           nextBlock = key;
    else if ((K != 256) & pivot)                  nextBlock = block;
    else if ((K == 256) & (state == S1) & done1)  nextBlock = {block[K-1: K-128], temp[127:0]};
    else if ((K == 256) & (state == S1))          nextBlock = {temp[K-1: K-128], block[127:0]};
    else if ((K == 256) & (state == S2) & done1)  nextBlock = {temp[K-1: K -128], block[127:0]};
    else if ((K == 256) & (state == S2))          nextBlock = {block[K-1: K -128], temp[127:0]};
    else if ((K != 128) & (state == S1) & !pivot) nextBlock = block;
    else                                          nextBlock = temp;

  // output logic
  always_comb
    case(state)
      S0: roundKey = 32'b0;
      S1: roundKey = (!wasdone1)? block[K-1: K-128]             : block[127:0];
      S2: roundKey = (!done1)?    block[127:0]                  : block[K-1: K-128];
      S3: roundKey = (!done1)?   {block[63:0], temp[K-1: K-64]} : {temp[63:0], block[K-1: K-64]};
      default: roundKey = 32'b0;
    endcase

endmodule