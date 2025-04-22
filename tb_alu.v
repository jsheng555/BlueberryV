`timescale 1ns / 1ps

module alu_tb;

    reg [31:0] A, B;
    reg [6:0] opcode;
    reg [2:0] funct3;
    reg [6:0] funct7;
    wire [31:0] result;

    // Instantiate ALU module
    alu uut (A, B, opcode, funct3, funct7, result);

    // Test procedure
    initial begin
        $display("Starting ALU testbench...");
        
        // SECTION 1: TEST DATA INSTRUCTIONS
        opcode = 7'b0110011;

        A = 33; B = 5; funct3 = 0; funct7 = 0; #1;
        if (result != 38) $fatal("ADD FAILED: got 0x%x", result);

        A = 33; B = 5; funct3 = 0; funct7 = 7'h20; #1;
        if (result != 28) $fatal("SUB FAILED: got 0x%x", result);

        A = 33; B = 5; funct3 = 4; funct7 = 0; #1;
        if (result != 36) $fatal("XOR FAILED: got 0x%x", result);

        A = 33; B = 5; funct3 = 6; funct7 = 0; #1;
        if (result != 37) $fatal("OR FAILED: got 0x%x", result);

        A = 33; B = 5; funct3 = 7; funct7 = 0; #1;
        if (result != 1) $fatal("AND FAILED: got 0x%x", result);

        A = 33; B = 5; funct3 = 1; funct7 = 0; #1;
        if (result != 1056) $fatal("SLL FAILED: got 0x%x", result);

        A = 33; B = 5; funct3 = 5; funct7 = 0; #1;
        if (result != 1) $fatal("SRL FAILED: got 0x%x", result);

        A = 32'hF0F0F0F0; B = 16; funct3 = 5; funct7 = 7'h20; #1;
        if (result != 32'hFFFFF0F0) $fatal("SRA FAILED: got 0x%x", result);

        A = 32'hFFFF0000; B = 32'h00001234; funct3 = 2; funct7 = 0; #1;
        if (result != 1) $fatal("SLT1 FAILED: got 0x%x", result);

        A = 32'hFFFFFFFF; B = 32'hFFEEDDCC; funct3 = 2; funct7 = 0; #1;
        if (result != 0) $fatal("SLT2 FAILED: got 0x%x", result);

        A = 32'hFFFF0000; B = 32'h00001234; funct3 = 3; funct7 = 0; #1;
        if (result != 0) $fatal("SLTU1 FAILED: got 0x%x", result);

        A = 32'hFFFFFFFF; B = 32'hFFEEDDCC; funct3 = 3; funct7 = 0; #1;
        if (result != 0) $fatal("SLTU2 FAILED: got 0x%x", result);


        // SECTION 2: TEST SPECIAL INSTRUCTIONS (LUI, AUIPC, LOADS, STORES, BRANCHES)
        opcode = 7'b0110111; A = 32'h00003000; B = 32'h12345000; #1;
        if (result != 32'h12345000) $fatal("LUI FAILED: got 0x%x", result);

        opcode = 7'b0010111; A = 32'h00003000; B = 32'h12345000; #1;
        if (result != 32'h12348000) $fatal("AUIPC FAILED: got 0x%x", result);

        opcode = 7'b0000011; A = 32'h00003000; B = 32'h50; #1;
        if (result != 32'h3050) $fatal("LOAD FAILED: got 0x%x", result);

        opcode = 7'b0100011; A = 32'h00003000; B = 32'h60; #1;
        if (result != 32'h3060) $fatal("STORE FAILED: got 0x%x", result);

        opcode = 7'b1100011; A = 32'h00003000; B = 32'h70; #1;
        if (result != 32'h3070) $fatal("BRANCH FAILED: got 0x%x", result);

        $display("All tests passed!");
        $finish;
    end

endmodule
