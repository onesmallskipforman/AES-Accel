module expand (input  logic          clk, reset,
               input  logic          predone,
               input  logic [127:0]  key,
               output logic [127:0]  wBlock);

  logic [31:0]  rcon, nextrcon, rotTemp, subTemp, rconTemp;
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

  rotate #(1, 4, 8) rw(lastBlock[31:0], rotTemp);
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
      nextrcon     = {rconFront, 24'b0};
    end else if (state == S2) begin
      temp[95:64]  = lastBlock[95:64]  ^ lastBlock[127:96];
      temp[63:32]  = lastBlock[63:32]  ^ lastBlock[95:64];
      temp[31:0]   = lastBlock[31:0]   ^ lastBlock[63:32];
      nextrcon     = {invrconFront, 24'b0};
    end else begin
      temp[95:0] = 96'b0;
      nextrcon   = rcon;
    end
  end

  assign wBlock   = (state == S0)? key:temp;

endmodule