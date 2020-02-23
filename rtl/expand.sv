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
    done:             done/disable bit signalling encryption completed
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

// module expand #(parameter K = 128)
//                (input  logic          clk, reset,
//                 input  logic          done,
//                 input  logic [K-1:0]  key,
//                 output logic [127:0]  roundKey);

//   logic [31:0]  rcon, nextrcon, transform, rotTemp, subTemp, rconTemp, subTransform, subOrgTemp;
//   logic [K-1:0] block, temp, nextBlock;
//   logic [7:0]   rconFront, invrconFront;
//   logic wasdone;

//   typedef enum logic [2:0] {S0, S1, S2, S3} statetype;
//   statetype state, nextstate;

//   always_ff @(posedge clk)
//     if (reset) begin
//       state       <= S0;
//       block       <= 32'b0;
//       rcon        <= 32'h8d000000;
//       wasdone     <= 1'b0;
//     end else begin//if (!done) begin
//       state       <= nextstate;
//       block       <= nextBlock;
//       rcon        <= nextrcon;
//       wasdone     <= done;  
//     end

//   parameter NR = (K == 128)? 10 : (K == 192)? 12 : 14;
//   parameter WIDTH = NR*128;
//   logic [WIDTH-1:0] bigroundkey;

//   always_ff @(posedge clk)
//     if      (reset)    bigroundkey <= {WIDTH{1'b0}};
//     else if (!wasdone) bigroundkey <= {roundKey, bigroundkey[WIDTH-1:128]};
//     else               bigroundkey <= {bigroundkey[(NR-1)*128:0], roundKey};

//   // next state logic
//   always_comb
//     case(state)
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

//   always_comb
//     if ((state == S0) | ((state == S1) & (K != 128))) nextrcon = rcon;
//     else                                              nextrcon = {rconFront, 24'b0};

//   // temp block logic
//   assign transform = block[31:0];
//   rotate #(1, 4, 8) rw(transform, rotTemp);
//   subword           sw(rotTemp, subTemp);
//   assign rconTemp       = subTemp         ^ nextrcon;
//   assign temp[K-1:K-32] = block[K-1:K-32] ^ rconTemp;

//   genvar i;
//   generate
//     for (i = K-32; i > 0; i=i-32) begin: tempAssign
//       // unique case for 256-bit expansion block
//       if ( (K == 256) && (i == 128) ) begin
//         assign subTransform = temp[i+32-1:i];
//         subword so(subTransform, subOrgTemp);
//         assign temp[i-1:i-32]  = block[i-1:i-32]^subOrgTemp;
//       end else begin
//         assign temp[i-1:i-32] = block[i-1:i-32]^temp[i+32-1:i];
//       end
//     end
//   endgenerate

//   // next expansion block logic
//   always_comb
//     if       (state == S0)               nextBlock = key;
//     else if ((K != 128) & (state == S1)) nextBlock = block;
//     else                                 nextBlock = temp;

//   // output logic
//   always_comb
//     if (done) roundKey = bigroundkey[WIDTH-1:(NR-1)*128];
//     else case(state)
//       S0: roundKey = 32'b0;
//       S1: roundKey = block[K-1: K-128];
//       S2: roundKey = block[127:0];
//       S3: roundKey = {block[63:0], temp[K-1: K-64]};
//       default: roundKey = 32'b0;
//     endcase
// endmodule



module expand #(parameter K = 128)
               (input  logic         clk, reset,
                input  logic         done,
                input  logic [K-1:0] key,
                output logic [127:0] roundKey);

  generate
    if (K == 128) begin expand128 e128(clk, reset, done, key, roundKey); end
    if (K == 192) begin expand192 e192(clk, reset, done, key, roundKey); end
    if (K == 256) begin expand256 e256(clk, reset, done, key, roundKey); end
  endgenerate

endmodule







module expand128 (input  logic          clk, reset,
                  input  logic          done,
                  input  logic [127:0]  key,
                  output logic [127:0]  block);

  logic [31:0]  rcon, nextrcon, rotTemp, subTemp, rconTemp;
  logic [127:0] block, nextBlock;
  logic [7:0]   rconFront;

  always_ff @(posedge clk)
    if (reset) begin
      block       <= 32'b0;
      rcon        <= 32'h8d000000;
    end else if (!done) begin
      block       <= nextBlock;
      rcon        <= nextrcon;  
    end

  // next round constant (rcon for current temp transform) logic
  galoismult    gm(rcon[31:24], rconFront);
  assign nextrcon = {rconFront, 24'b0};

  // next block logic
  rotate #(1, 4, 8) rw(block[31:0], rotTemp);
  subword           sw(rotTemp, subTemp);
  assign rconTemp       = subTemp ^ nextrcon;

  always_comb begin
    nextBlock[127:96] = block[127:96]  ^ rconTemp;
    nextBlock[95:64]  = (block[95:64]  ^ nextBlock[127:96]);
    nextBlock[63:32]  = (block[63:32]  ^ nextBlock[95:64]);
    nextBlock[31:0]   = (block[31:0]   ^ nextBlock[63:32]);
  end

endmodule





// module expand256 (input  logic          clk, reset,
//                   input  logic          done1,
//                   input  logic          done2,
//                   input  logic [255:0]  key,
//                   output logic [127:0]  roundKey);

//   logic [31:0]  rcon, nextrcon, transform, rotTemp, subTemp, rconTemp, tosub;
//   logic [255:0] block, nextBlock;
//   logic [127:0] temp, replace;
//   logic [7:0]   rconFront, invrconFront;
//   logic         wasdone1, pivot;

//   typedef enum logic {S0, S1} statetype;
//   statetype state, nextstate;

//   always_ff @(posedge clk)
//     if (reset) begin
//       state       <= S0;
//       block       <= key;
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
//     case (state)
//       S0:      nextstate = S1;
//       S1:      nextstate = S0;
//       default: nextstate = S0;
//     endcase

//   // next round constant (rcon for current temp transform) logic
//   galoismult    gm(rcon[31:24], rconFront);
//   invgaloismult ig(rcon[31:24], invrconFront);

//   always_comb
//     if      (pivot) nextrcon = rcon;
//     else if (done1) nextrcon = {invrconFront, 24'b0};
//     else            nextrcon = {rconFront, 24'b0};

//   // temp block logic
//   assign transform = (state == S0)? block[31:0] : block[159:128];
//   rotate #(1, 4, 8) rw(transform, rotTemp);
//   assign tosub = (state == S0)? rotTemp : transform;
//   subword sw(tosub, subTemp);
//   assign rconTemp = subTemp ^ nextrcon;
//   assign replace = (state == S0)? block[255:128] : block[127:0];

//   always_comb begin
//     temp[127:96] = (state == S0)? (replace[127:96] ^ rconTemp)     : (replace[127:96] ^ subTemp);
//     temp[95:64]  = (!done1)?      (replace[95:64]  ^ temp[127:96]) : (replace[95:64]  ^ replace[127:96]);
//     temp[63:32]  = (!done1)?      (replace[63:32]  ^ temp[95:64])  : (replace[63:32]  ^ replace[95:64]);
//     temp[31:0]   = (!done1)?      (replace[31:0]   ^ temp[63:32])  : (replace[31:0]   ^ replace[63:32]);
//   end

//   // next expansion block and output logic
//   assign nextBlock = (state == S0)? {temp, block[127:0]} : {block[255:128], temp};
//   assign roundKey  = (state == S0)?  block[255: 128]     :  block[127:0];

// endmodule



// module expand192 (input  logic          clk, reset,
//                   input  logic          done1,
//                   input  logic          done2,
//                   input  logic [191:0]  key,
//                   output logic [127:0]  roundKey);

//   logic [31:0]  rcon, nextrcon, transform, rotTemp, subTemp, rconTemp, tosub;
//   logic [191:0] block, nextBlock;
//   logic [127:0] temp, replace;
//   logic [7:0]   rconFront, invrconFront;
//   logic         wasdone1, pivot;

//   typedef enum logic [1:0] {S0, S1, S2} statetype;
//   statetype state, nextstate;

//   always_ff @(posedge clk)
//     if (reset) begin
//       state       <= S0;
//       block       <= key;
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
//     case (state)
//       S0: if (!done1) nextstate = S1;
//           else        nextstate = S2;
//       S1: if (!done1) nextstate = S2;
//           else        nextstate = S0;
//       S2: if (!done1) nextstate = S0;
//           else        nextstate = S1;
//       default:        nextstate = S0;
//     endcase

//   // next round constant (rcon for current temp transform) logic
//   galoismult    gm(rcon[31:24], rconFront);
//   invgaloismult ig(rcon[31:24], invrconFront);

//   always_comb
//     if      (pivot) nextrcon = rcon;
//     else if (done1) nextrcon = {invrconFront, 24'b0};
//     else            nextrcon = {rconFront, 24'b0};

//   // temp block logic
//   assign transform = (state == S0)? block[31:0] : block[159:128];
//   rotate #(1, 4, 8) rw(transform, rotTemp);
//   assign tosub = (state == S0)? rotTemp : transform;
//   subword sw(tosub, subTemp);
//   assign rconTemp = subTemp^nextrcon;

//   always_comb
//     if      (state == S0) replace =  block[191:64];
//     else if (state == S1) replace = {block[63:0], block[191:128]};
//     else                  replace = block[127:0];

//   always_comb begin
//     if      (state == S0) temp[127:96] = replace[127:96] ^ rconTemp;
//     else if (state == S1) temp[127:96] = replace[127:96] ^ block[95:64];
//     else                  temp[127:96] = replace[127:96] ^ block[159:128];

//     temp[95:64] = (!done1)? (replace[95:64]^temp[127:96]) : (replace[95:64]^replace[127:96]);

//     if (state == S1) temp[63:32] =            replace[63:32] ^ rconTemp;
//     else             temp[63:32] = (!done1)? (replace[63:32] ^ temp[95:64]) : (replace[63:32] ^ replace[95:64]);

//     temp[31:0] = (!done1)? (replace[31:0]^temp[63:32]) : (replace[31:0]^replace[63:32]);
//   end

//   // next expansion block and output logic
//   always_comb begin
//     if      (state == S0) nextBlock = {temp, block[63:0]};
//     else if (state == S2) nextBlock = {block[127:64], temp};
//     else                  nextBlock = {temp[63:0], block[127:64], temp[127:64]};

//     if      (state == S0) roundKey =  block[191:160];
//     else if (state == S1) roundKey = {block[63:0], block[191:160]};
//     else                  roundKey =  block[127:0];
//   end

// endmodule


















