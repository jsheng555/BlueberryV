// The register file.

module register(CLK, RegW, DR, SR1, SR2, Reg_In, ReadReg1, ReadReg2);
  input CLK;
  input RegW;
  input [4:0] DR;
  input [4:0] SR1;
  input [4:0] SR2;
  input [31:0] Reg_In;
  output [31:0] ReadReg1;
  output [31:0] ReadReg2;

  reg [31:0] REG [0:31];
  
  integer j;
  initial begin
    for (j = 0 ; j < 32 ; j = j + 1) begin
      REG[j] = 32'h0000000;
    end
  end

  always @(posedge CLK)
  begin
    if(RegW == 1'b1 && DR != 5'b00000) REG[DR] <= Reg_In[31:0];
    REG[0] <= 0; // x0 is hardwired to be 0
  end

  assign ReadReg1 = (SR1 == 5'd0) ? 32'b0 : REG[SR1];
  assign ReadReg2 = (SR2 == 5'd0) ? 32'b0 : REG[SR2];
endmodule