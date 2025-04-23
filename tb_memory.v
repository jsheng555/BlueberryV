`timescale 1ns/1ps

module memory_tb;

    reg CLK;
    reg WE;
    reg [15:0] ADDR;
    wire [31:0] BUS;
    reg [1:0] DATA_SIZE;
    reg SIGNED;

    wire [31:0] INSTR;

    reg [31:0] bus_driver;
    assign BUS = (WE) ? bus_driver : 32'bz;

    dataMemory data_mem(
        .WE(WE),
        .CLK(CLK),
        .ADDR(ADDR),
        .BUS(BUS),
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
        // Write known pattern

        // BYTE
        ADDR = 16'h0000; bus_driver = 32'h000000AB; DATA_SIZE = 2'b00; SIGNED = 0; #5 CLK = 0; #5 CLK = 1;

        // HALFWORD
        ADDR = 16'h0010; bus_driver = 32'h0000CDEF; DATA_SIZE = 2'b01; SIGNED = 0; #5 CLK = 0; #5 CLK = 1;

        // WORD
        ADDR = 16'h0020; bus_driver = 32'h12345678; DATA_SIZE = 2'b10; SIGNED = 0; #5 CLK = 0; #5 CLK = 1;

        // Now read back (WE=0)
        WE = 0;

        // BYTE UNSIGNED
        ADDR = 16'h0000; DATA_SIZE = 2'b00; SIGNED = 0; #5 CLK = 0; #5 CLK = 1;
        if (BUS !== 32'h000000AB) begin $display("BYTE UNSIGNED FAILED: BUS=%h", BUS); errors = errors + 1; end

        // BYTE SIGNED
        ADDR = 16'h0000; DATA_SIZE = 2'b00; SIGNED = 1; #5 CLK = 0; #5 CLK = 1;
        if (BUS !== {32'hFFFFFFAB}) begin $display("BYTE SIGNED FAILED: BUS=%h", BUS); errors = errors + 1; end

        // HALFWORD UNSIGNED
        ADDR = 16'h0010; DATA_SIZE = 2'b01; SIGNED = 0; #5 CLK = 0; #5 CLK = 1;
        if (BUS !== 32'h0000CDEF) begin $display("HALFWORD UNSIGNED FAILED: BUS=%h", BUS); errors = errors + 1; end

        // HALFWORD SIGNED
        ADDR = 16'h0010; DATA_SIZE = 2'b01; SIGNED = 1; #5 CLK = 0; #5 CLK = 1;
        if (BUS !== {32'hFFFFCDEF}) begin $display("HALFWORD SIGNED FAILED: BUS=%h", BUS); errors = errors + 1; end

        // WORD (SIGNED/UNSIGNED doesn't matter for full word)
        ADDR = 16'h0020; DATA_SIZE = 2'b10; SIGNED = 0; #5 CLK = 0; #5 CLK = 1;
        if (BUS !== 32'h12345678) begin $display("WORD FAILED: BUS=%h", BUS); errors = errors + 1; end

        ADDR = 16'h0020; DATA_SIZE = 2'b10; SIGNED = 1; #5 CLK = 0; #5 CLK = 1;
        if (BUS !== 32'h12345678) begin $display("WORD SIGNED FAILED: BUS=%h", BUS); errors = errors + 1; end


        // Test Instruction Memory - Write manually to file or pre-fill RAM
        // Assume contents: address 0x1000 = 0xDEADBEEF

        // Check instruction fetch
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

    // always #5 CLK = ~CLK;

endmodule
