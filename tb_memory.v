`timescale 1ns/1ps

module memory_tb;

    reg CLK;
    reg WE;
    reg [15:0] ADDR;
    reg [31:0] DATA_IN;
    wire [31:0] DATA_OUT;
    reg [1:0] DATA_SIZE;
    reg SIGNED;

    wire [31:0] INSTR;

    dataMemory data_mem(
        .WE(WE),
        .CLK(CLK),
        .ADDR(ADDR),
        .DATA_IN(DATA_IN),
        .DATA_OUT(DATA_OUT),
        .DATA_SIZE(DATA_SIZE),
        .SIGNED(SIGNED)
    );

    instrMemory instr_mem(
        .CLK(CLK),
        .ADDR(ADDR),
        .INSTR(INSTR)
    );

    integer errors;

    initial begin
        CLK = 0;
        errors = 0;

        // Test Data Memory - All DATA_SIZE and SIGNED combinations
        WE = 1;

        // BYTE
        ADDR = 16'h0000; DATA_IN = 32'h000000AB; DATA_SIZE = 2'b00; SIGNED = 0; #5 CLK = 0; #5 CLK = 1;

        // HALFWORD
        ADDR = 16'h0010; DATA_IN = 32'h0000CDEF; DATA_SIZE = 2'b01; SIGNED = 0; #5 CLK = 0; #5 CLK = 1;

        // WORD
        ADDR = 16'h0020; DATA_IN = 32'h12345678; DATA_SIZE = 2'b10; SIGNED = 0; #5 CLK = 0; #5 CLK = 1;

        // Now read back (WE=0)
        WE = 0;

        // BYTE UNSIGNED
        ADDR = 16'h0000; DATA_SIZE = 2'b00; SIGNED = 0; #5 CLK = 0; #5 CLK = 1;
        if (DATA_OUT !== 32'h000000AB) begin $display("BYTE UNSIGNED FAILED: DATA_OUT=%h", DATA_OUT); errors = errors + 1; end

        // BYTE SIGNED
        ADDR = 16'h0000; DATA_SIZE = 2'b00; SIGNED = 1; #5 CLK = 0; #5 CLK = 1;
        if (DATA_OUT !== 32'hFFFFFFAB) begin $display("BYTE SIGNED FAILED: DATA_OUT=%h", DATA_OUT); errors = errors + 1; end

        // HALFWORD UNSIGNED
        ADDR = 16'h0010; DATA_SIZE = 2'b01; SIGNED = 0; #5 CLK = 0; #5 CLK = 1;
        if (DATA_OUT !== 32'h0000CDEF) begin $display("HALFWORD UNSIGNED FAILED: DATA_OUT=%h", DATA_OUT); errors = errors + 1; end

        // HALFWORD SIGNED
        ADDR = 16'h0010; DATA_SIZE = 2'b01; SIGNED = 1; #5 CLK = 0; #5 CLK = 1;
        if (DATA_OUT !== 32'hFFFFCDEF) begin $display("HALFWORD SIGNED FAILED: DATA_OUT=%h", DATA_OUT); errors = errors + 1; end

        // WORD (SIGNED/UNSIGNED doesn't matter for full word)
        ADDR = 16'h0020; DATA_SIZE = 2'b10; SIGNED = 0; #5 CLK = 0; #5 CLK = 1;
        if (DATA_OUT !== 32'h12345678) begin $display("WORD FAILED: DATA_OUT=%h", DATA_OUT); errors = errors + 1; end

        ADDR = 16'h0020; DATA_SIZE = 2'b10; SIGNED = 1; #5 CLK = 0; #5 CLK = 1;
        if (DATA_OUT !== 32'h12345678) begin $display("WORD SIGNED FAILED: DATA_OUT=%h", DATA_OUT); errors = errors + 1; end


        // Test Instruction Memory
        // Program is loaded in from program.mem
        ADDR = 16'h0000; #5 CLK = 0; #5 CLK = 1;
        if (INSTR !== 32'hDEADBEEF) begin
            $display("INSTRUCTION MEMORY FAILED: INSTR=%h", INSTR);
            errors = errors + 1;
        end

        ADDR = 16'h0004; #5 CLK = 0; #5 CLK = 1;
        if (INSTR !== 32'hCAFEBABE) begin
            $display("INSTRUCTION MEMORY FAILED: INSTR=%h", INSTR);
            errors = errors + 1;
        end

        if (errors == 0)
            $display("ALL TESTS PASSED");
        else
            $display("TEST FAILED WITH %0d ERRORS", errors);

        $finish;
    end

endmodule
