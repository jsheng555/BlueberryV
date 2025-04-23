`timescale 1ns/1ps

// Useful definitions
`define R (3'd0);
`define I (3'd1);
`define S (3'd2);
`define B (3'd3);
`define U (3'd4);
`define J (3'd5);
`define Q (3'd7);

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

    wire ME_V;
    wire [2:0] ME_F3;
    wire [4:0] ME_RD;
    wire [31:0] ME_ALU_RE;
    wire ME_BRT;
    wire [15:0] ME_NPC;
    wire [31:0] ME_RS2;
    wire [2:0] ME_TYPE;

    wire WB_V;
    wire [4:0] WB_RD;
    wire [31:0] WB_ALU_RE;
    wire [31:0] WB_MEM_RE;
    wire [15:0] WB_NPC;
    wire [2:0] WB_TYPE;

    // Set up register file
    wire [4:0] Reg1, Reg2; // from decode stage
    wire [31:0] ReadReg1, ReadReg2; // for decode stage
    wire RegW; // from writeback stage
    wire [4:0] DR; // for writeback stage
    wire [31:0] Reg_In; // for writeback stage

    // temporary until WB stage is done
    assign RegW = 0; assign DR = 0; assign Reg_In = 0;

    register RF(CLK, RegW, DR, Reg1, Reg2, Reg_In, ReadReg1, ReadReg2);

    // Create pipeline
    fetch_stage FS(CLK, ME_BRT, ME_ALU_RE, DE_V, DE_IR, DE_PC);
    decode_stage DS(CLK, DE_V, DE_IR, DE_PC, EX_V, EX_IMM, EX_F3, EX_F7, EX_OP, EX_RD, EX_RS1, EX_RS2, EX_PC, EX_TYPE, Reg1, Reg2, ReadReg1, ReadReg2);

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

    initial PC = 0;

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

module decode_stage(CLK, DE_V, DE_IR, DE_PC, EX_V, EX_IMM, EX_F3, EX_F7, EX_OP, EX_RD, EX_RS1, EX_RS2, EX_PC, EX_TYPE, Reg1, Reg2, ReadReg1, ReadReg2);
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
    output [4:0] Reg1;
    output [4:0] Reg2;
    input [31:0] ReadReg1;
    input [31:0] ReadReg2;

    // register file connections
    assign Reg1 = DE_IR[19:15];
    assign Reg2 = DE_IR[24:20];

    // internal signals
    wire [6:0] opcode;
    wire [2:0] type;
    wire [31:0] imm;

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
    end

endmodule



// The execute stage of the pipeline.

module execute_stage();

endmodule



// The memory stage of the pipeline.

module memory_stage();

endmodule



// The writeback stage of the pipeline.

module writeback_stage();

endmodule