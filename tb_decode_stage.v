`timescale 1ns / 1ps

module decode_stage_tb;

    reg CLK;
    reg DE_V;
    reg [31:0] DE_IR;
    reg [15:0] DE_PC;
    wire [4:0] Reg1;
    wire [4:0] Reg2;
    reg [31:0] ReadReg1;
    reg [31:0] ReadReg2;

    wire EX_V;
    wire [31:0] EX_IMM;
    wire [2:0] EX_F3;
    wire [6:0] EX_F7;
    wire [6:0] EX_OP;
    wire [4:0] EX_RD;
    wire [31:0] EX_RS1;
    wire [31:0] EX_RS2;
    wire [15:0] EX_PC;
    wire [2:0] EX_TYPE;

    // Instantiate the module
    decode_stage uut (
        .CLK(CLK),
        .DE_V(DE_V),
        .DE_IR(DE_IR),
        .DE_PC(DE_PC),
        .EX_V(EX_V),
        .EX_IMM(EX_IMM),
        .EX_F3(EX_F3),
        .EX_F7(EX_F7),
        .EX_OP(EX_OP),
        .EX_RD(EX_RD),
        .EX_RS1(EX_RS1),
        .EX_RS2(EX_RS2),
        .EX_PC(EX_PC),
        .EX_TYPE(EX_TYPE),
        .Reg1(Reg1),
        .Reg2(Reg2),
        .ReadReg1(ReadReg1),
        .ReadReg2(ReadReg2)
    );

    // Clock generation
    initial begin
        CLK = 0;
        forever #5 CLK = ~CLK; // 10ns period
    end

    // Stimulus
    initial begin
        // Initialize
        DE_V = 1;
        ReadReg1 = 32'hAAAAAAAA;
        ReadReg2 = 32'h55555555;

        // Wait a little bit
        #10;

        // Test ADDI x1, x2, 5   --> opcode = 0010011
        DE_IR = {12'd5, 5'd2, 3'b000, 5'd1, 7'b0010011}; // addi x1, x2, 5
        DE_PC = 16'h1000;
        #10;
        $display("TEST 1\nIMM: %x\nF3: %x\nF7: %x\nOP: %x\nRD: %x\nRS1: %x\nRS2: %x\nPC: %x\nTYPE: %x\n",
                 EX_IMM, EX_F3, EX_F7, EX_OP, EX_RD, EX_RS1, EX_RS2, EX_PC, EX_TYPE);

        // Test LW x3, -1(x5)  --> opcode = 0000011
        DE_IR = {12'hFFF, 5'd5, 3'b010, 5'd3, 7'b0000011}; // lw x3, -1(x5)
        DE_PC = 16'h1004;
        #10;
        $display("TEST 2\nIMM: %x\nF3: %x\nF7: %x\nOP: %x\nRD: %x\nRS1: %x\nRS2: %x\nPC: %x\nTYPE: %x\n",
                 EX_IMM, EX_F3, EX_F7, EX_OP, EX_RD, EX_RS1, EX_RS2, EX_PC, EX_TYPE);

        // Test SW x6, 8(x7) --> opcode = 0100011
        DE_IR = {7'd0, 5'd6, 5'd7, 3'b010, 5'd8, 7'b0100011}; // sw x6, 8(x7)
        DE_PC = 16'h1008;
        #10;
        $display("TEST 3\nIMM: %x\nF3: %x\nF7: %x\nOP: %x\nRD: %x\nRS1: %x\nRS2: %x\nPC: %x\nTYPE: %x\n",
                 EX_IMM, EX_F3, EX_F7, EX_OP, EX_RD, EX_RS1, EX_RS2, EX_PC, EX_TYPE);

        $stop;
    end

endmodule
