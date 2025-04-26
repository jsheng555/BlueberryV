`timescale 1ns/1ps

// Useful definitions
`define R (3'd0)
`define I (3'd1)
`define S (3'd2)
`define B (3'd3)
`define U (3'd4)
`define J (3'd5)
`define Q (3'd7)

// The pipelined CPU.

module cpu(CLK);
    input CLK;

    // Set up latches between pipeline stages
    wire DE_V;
    wire [31:0] DE_IR;
    wire [15:0] DE_PC;

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
    wire EX_LINK;
    wire EX_LD;

    wire ME_V;
    wire [2:0] ME_F3;
    wire [4:0] ME_RD;
    wire [31:0] ME_ALU_RE;
    wire ME_BRT;
    wire [15:0] ME_NPC;
    wire [31:0] ME_RS2;
    wire [2:0] ME_TYPE;
    wire ME_LINK;
    wire ME_LD;

    wire WB_V;
    wire [4:0] WB_RD;
    wire [31:0] WB_ALU_RE;
    wire [31:0] WB_MEM_RE;
    wire [15:0] WB_NPC;
    wire [2:0] WB_TYPE;
    wire WB_LINK;
    wire WB_LD;

    // Set up register file
    wire [4:0] Reg1, Reg2; // from decode stage
    wire [31:0] ReadReg1, ReadReg2; // for decode stage
    wire RegW; // from writeback stage
    wire [4:0] DR; // for writeback stage
    wire [31:0] Reg_In; // for writeback stage

    // temporary until WB stage is done
    // assign RegW = 0; assign DR = 0; assign Reg_In = 0;

    register RF(CLK, RegW, DR, Reg1, Reg2, Reg_In, ReadReg1, ReadReg2);

    // Create pipeline
    fetch_stage FS(CLK, ME_BRT, ME_ALU_RE, DE_V, DE_IR, DE_PC);
    decode_stage DS(CLK, DE_V, DE_IR, DE_PC, EX_V, EX_IMM, EX_F3, EX_F7, EX_OP, EX_RD, EX_RS1, EX_RS2, EX_PC, EX_TYPE, EX_LINK, EX_LD, Reg1, Reg2, ReadReg1, ReadReg2);
    execute_stage ES(CLK, EX_V, EX_IMM, EX_F3, EX_F7, EX_OP, EX_RD, EX_RS1, EX_RS2, EX_PC, EX_TYPE, EX_LINK, EX_LD, ME_V, ME_F3, ME_RD, ME_ALU_RE, ME_BRT, ME_NPC, ME_RS2, ME_TYPE, ME_LINK, ME_LD);
    memory_stage MS(CLK, ME_V, ME_F3, ME_RD, ME_ALU_RE, ME_NPC, ME_RS2, ME_TYPE, ME_LINK, ME_LD, WB_V, WB_RD, WB_ALU_RE, WB_MEM_RE, WB_NPC, WB_TYPE, WB_LINK, WB_LD);
    writeback_stage WS(CLK, WB_V, WB_RD, WB_ALU_RE, WB_MEM_RE, WB_NPC, WB_TYPE, WB_LINK, WB_LD, Reg_In, DR, RegW);

endmodule



// The fetch stage of the pipeline.

module fetch_stage(CLK, ME_BRT, ME_ALU_RE, DE_V, DE_IR, DE_PC);
    input CLK;
    input ME_BRT;
    input [31:0] ME_ALU_RE;
    output reg DE_V;
    output reg [31:0] DE_IR;
    output reg [15:0] DE_PC;

    reg [15:0] PC;
    wire [31:0] IM_OUT;

    instrMemory IM(CLK, PC, IM_OUT);

    initial begin 
        PC = 0;
        DE_V = 0;
        DE_IR = 0;
        DE_PC = 0;
    end

    always @ (posedge CLK) begin
        // internal latches
        PC <= ME_BRT ? ME_ALU_RE[15:0] : (PC+4);

        // next stage latches
        DE_IR <= IM_OUT;
        DE_PC <= PC;
        DE_V <= 1;
    end

endmodule



// The decode stage of the pipeline.

module decode_stage(CLK, DE_V, DE_IR, DE_PC, EX_V, EX_IMM, EX_F3, EX_F7, EX_OP, EX_RD, EX_RS1, EX_RS2, EX_PC, EX_TYPE, EX_LINK, EX_LD, Reg1, Reg2, ReadReg1, ReadReg2);
    input CLK;
    input DE_V;
    input [31:0] DE_IR;
    input [15:0] DE_PC;
    output reg EX_V;
    output reg [31:0] EX_IMM;
    output reg [2:0] EX_F3;
    output reg [6:0] EX_F7;
    output reg [6:0] EX_OP;
    output reg [4:0] EX_RD;
    output reg [31:0] EX_RS1;
    output reg [31:0] EX_RS2;
    output reg [15:0] EX_PC;
    output reg [2:0] EX_TYPE;
    output reg EX_LINK;
    output reg EX_LD;
    output [4:0] Reg1;
    output [4:0] Reg2;
    input [31:0] ReadReg1;
    input [31:0] ReadReg2;

    initial begin
        EX_V = 0;
        EX_IMM = 0;
        EX_F3 = 0;
        EX_F7 = 0;
        EX_OP = 0;
        EX_RD = 0;
        EX_RS1 = 0;
        EX_RS2 = 0;
        EX_PC = 0;
        EX_TYPE = 0;
        EX_LINK = 0;
        EX_LD = 0;
    end

    // register file connections
    assign Reg1 = DE_IR[19:15];
    assign Reg2 = DE_IR[24:20];

    // internal signals
    wire [6:0] opcode;
    wire [2:0] type;
    wire [31:0] imm;
    wire link, ld;

    assign opcode = DE_IR[6:0];
    assign type = (opcode == 7'b0110011) ? `R :
                  (opcode == 7'b0010011) ? `I : 
                  (opcode == 7'b0000011) ? `I : 
                  (opcode == 7'b0100011) ? `S : 
                  (opcode == 7'b1100011) ? `B :
                  (opcode == 7'b1101111) ? `J :
                  (opcode == 7'b1100111) ? `I :   
                  (opcode == 7'b0110111) ? `U : 
                  (opcode == 7'b0010111) ? `I : `Q;
    assign imm = (type == `I) ? {{20{DE_IR[31]}}, DE_IR[31:20]} :
                 (type == `S) ? {{20{DE_IR[31]}}, DE_IR[31:25], DE_IR[11:7]} :
                 (type == `B) ? {{19{DE_IR[31]}}, DE_IR[31], DE_IR[7], DE_IR[30:25], DE_IR[11:8], 1'b0} :
                 (type == `U) ? {DE_IR[31:12], 12'b0} :
                 (type == `J) ? {{11{DE_IR[31]}}, DE_IR[31], DE_IR[19:12], DE_IR[20], DE_IR[30:21], 1'b0} : 0;
    assign link = (opcode == 7'b1101111 || opcode == 7'b1100111);
    assign ld = (opcode == 7'b0000011);

    // next stage latches
    always @ (posedge CLK) begin
        EX_V <= 1;
        EX_IMM <= imm;
        EX_F3 <= DE_IR[14:12];
        EX_F7 <= DE_IR[31:25];
        EX_OP <= opcode;
        EX_RD <= DE_IR[11:7];
        EX_RS1 <= ReadReg1;
        EX_RS2 <= ReadReg2;
        EX_PC <= DE_PC;
        EX_TYPE <= type;
        EX_LINK <= link;
        EX_LD <= ld;
    end

endmodule



// The execute stage of the pipeline.

module execute_stage(CLK, EX_V, EX_IMM, EX_F3, EX_F7, EX_OP, EX_RD, EX_RS1, EX_RS2, EX_PC, EX_TYPE, EX_LINK, EX_LD, ME_V, ME_F3, ME_RD, ME_ALU_RE, ME_BRT, ME_NPC, ME_RS2, ME_TYPE, ME_LINK, ME_LD);
    input CLK;
    input EX_V;
    input [31:0] EX_IMM;
    input [2:0] EX_F3;
    input [6:0] EX_F7;
    input [6:0] EX_OP;
    input [4:0] EX_RD;
    input [31:0] EX_RS1;
    input [31:0] EX_RS2;
    input [15:0] EX_PC;
    input [2:0] EX_TYPE;
    input EX_LINK;
    input EX_LD;
    output reg ME_V;
    output reg [2:0] ME_F3;
    output reg [4:0] ME_RD;
    output reg [31:0] ME_ALU_RE;
    output reg ME_BRT;
    output reg [15:0] ME_NPC;
    output reg [31:0] ME_RS2;
    output reg [2:0] ME_TYPE;
    output reg ME_LINK;
    output reg ME_LD;

    wire [31:0] ALU_result;
    wire [31:0] ALU_A;
    wire [31:0] ALU_B;
    reg CMP_out;
    wire signed [31:0] RS1_s;
    wire signed [31:0] RS2_s;

    initial begin 
        ME_V = 0;
        ME_F3 = 0;
        ME_RD = 0;
        ME_ALU_RE = 0;
        ME_BRT = 0;
        ME_NPC = 0;
        ME_RS2 = 0;
        ME_TYPE = 0;
        ME_LINK = 0;
        ME_LD = 0;
        CMP_out = 0;
    end

    assign RS1_s = EX_RS1;
    assign RS2_s = EX_RS2;
    assign ALU_A = (EX_TYPE == `R || EX_TYPE == `I ||EX_TYPE == `S) ? EX_RS1 : EX_PC;
    assign ALU_B = (EX_TYPE == `R) ? EX_RS2 : EX_IMM;

    // Comparator
    always @ (*) begin
        CMP_out = 0;
        if (EX_TYPE == `B) begin
            case (EX_F3)
                3'd0: CMP_out = (EX_RS1 == EX_RS2);
                3'd1: CMP_out = (EX_RS1 != EX_RS2);
                3'd4: CMP_out = (RS1_s < RS2_s);
                3'd5: CMP_out = (RS1_s >= RS2_s);
                3'd6: CMP_out = (EX_RS1 < EX_RS2);
                3'd7: CMP_out = (EX_RS1 >= EX_RS2);
                default: begin CMP_out = 0; $fatal("Invalid branch funct3 code"); end
            endcase
        end
    end

    // ALU
    alu ALUUnit(ALU_A, ALU_B, EX_OP, EX_F3, EX_F7, ALU_result);

    // Latches
    always @ (posedge CLK) begin
        ME_V <= 1;
        ME_F3 <= EX_F3;
        ME_RD <= EX_RD;
        ME_ALU_RE <= ALU_result;
        ME_BRT <= CMP_out || EX_LINK;
        ME_NPC <= EX_PC + 4;
        ME_RS2 <= EX_RS2;
        ME_TYPE <= EX_TYPE;
        ME_LINK <= EX_LINK;
        ME_LD <= EX_LD;
    end
endmodule



// The memory stage of the pipeline.

module memory_stage(CLK, ME_V, ME_F3, ME_RD, ME_ALU_RE, ME_NPC, ME_RS2, ME_TYPE, ME_LINK, ME_LD, WB_V, WB_RD, WB_ALU_RE, WB_MEM_RE, WB_NPC, WB_TYPE, WB_LINK, WB_LD);
    input CLK;
    input ME_V;
    input [2:0] ME_F3;
    input [4:0] ME_RD;
    input [31:0] ME_ALU_RE;
    input [15:0] ME_NPC;
    input [31:0] ME_RS2;
    input [2:0] ME_TYPE;
    input ME_LINK;
    input ME_LD;

    output reg WB_V;
    output reg [4:0] WB_RD;
    output reg [31:0] WB_ALU_RE;
    output reg [31:0] WB_MEM_RE;
    output reg [15:0] WB_NPC;
    output reg [2:0] WB_TYPE;
    output reg WB_LINK;
    output reg WB_LD;

    initial begin
        WB_V = 0;
        WB_RD = 0;
        WB_ALU_RE = 0;
        WB_MEM_RE = 0;
        WB_NPC = 0;
        WB_TYPE = 0;
        WB_LINK = 0;
        WB_LD = 0;
    end

    // Internal signals
    wire [1:0] DATA_SIZE;
    wire SIGNED, WE;
    wire [31:0] DATA_OUT;

    assign WE = (ME_TYPE == `S);
    assign DATA_SIZE = ME_F3[1:0];
    assign SIGNED = !ME_F3[2];

    // Data memory
    dataMemory DM(WE, CLK, ME_ALU_RE, ME_RS2, DATA_SIZE, SIGNED, DATA_OUT);

    // Latches
    always @ (posedge CLK) begin
        WB_V <= 1;
        WB_RD <= ME_RD;
        WB_ALU_RE <= ME_ALU_RE;
        WB_MEM_RE <= DATA_OUT;
        WB_NPC <= ME_NPC;
        WB_TYPE <= ME_TYPE;
        WB_LINK <= ME_LINK;
        WB_LD <= ME_LD;
    end

endmodule



// The writeback stage of the pipeline.

module writeback_stage(CLK, WB_V, WB_RD, WB_ALU_RE, WB_MEM_RE, WB_NPC, WB_TYPE, WB_LINK, WB_LD, RF_DATA_IN, RF_RD, REGW);
    input CLK;
    input WB_V;
    input [4:0] WB_RD;
    input [31:0] WB_ALU_RE;
    input [31:0] WB_MEM_RE;
    input [15:0] WB_NPC;
    input [2:0] WB_TYPE;
    input WB_LINK;
    input WB_LD;
    output [31:0] RF_DATA_IN;
    output [4:0] RF_RD;
    output REGW;

    // Combinational logic
    reg [31:0] RFMUX;
    always @ (*) begin
        if (WB_LINK) RFMUX = WB_NPC;
        else if (WB_LD) RFMUX = WB_MEM_RE;
        else RFMUX = WB_ALU_RE;
    end

    assign RF_RD = WB_RD;
    assign REGW = (WB_TYPE == `R || WB_TYPE == `I || WB_TYPE == `J || WB_TYPE == `U);
    assign RF_DATA_IN = RFMUX;

endmodule