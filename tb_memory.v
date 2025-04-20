`timescale 1ns / 1ps

module memory_tb;

    reg CS;
    reg WE;
    reg CLK;
    reg [19:0] DATA_ADDR, INSTR_ADDR;
    reg [1:0] DATA_SIZE;
    reg SIGNED;
    wire [31:0] DATA_BUS;
    wire [31:0] INSTR_BUS;
    reg [31:0] data_drive;

    // Bus trickery: drive only during writes
    assign DATA_BUS = (CS && WE) ? data_drive : 32'bZ;

    // Instantiate your memory module
    memory uut (
        .CS(CS),
        .WE(WE),
        .CLK(CLK),
        .INSTR_ADDR(INSTR_ADDR),
        .DATA_ADDR(DATA_ADDR),
        .DATA_SIZE(DATA_SIZE),
        .SIGNED(SIGNED),
        .DATA_BUS(DATA_BUS),
        .INSTR_BUS(INSTR_BUS)
    );

    // Clock generation
    initial begin
        CLK = 0;
        forever #5 CLK = ~CLK; // 10ns period
    end

    // Test procedure
    initial begin
        $display("Starting memory testbench...");
        
        CS = 0; WE = 0;
        DATA_ADDR = 0;
        INSTR_ADDR = 0;
        DATA_SIZE = 2'b00;
        SIGNED = 0;
        data_drive = 32'b0;

        // Let memory initialize
        #20;

        // --------------------
        // TEST 1: Byte write/read
        // --------------------
        CS = 1; WE = 1; // enable, write
        DATA_ADDR = 20'h13;
        DATA_SIZE = 2'b00; // byte
        data_drive = 32'h000000AA; // Only low 8 bits used

        @(negedge CLK); #1;

        CS = 1; WE = 0; // now read
        data_drive = 32'b0; // stop driving
        
        SIGNED = 0; // unsigned read
        @(negedge CLK); #1;

        if (DATA_BUS !== 32'h000000AA) $fatal("BYTE READ FAILED: got %h", DATA_BUS);
        $display("BYTE READ PASSED: %h", DATA_BUS);

        // --------------------
        // TEST 2: Halfword write/read
        // --------------------
        CS = 1; WE = 1;
        DATA_ADDR = 20'h22;
        DATA_SIZE = 2'b01; // halfword
        data_drive = 32'h0000BEEF; // only low 16 bits used

        @(negedge CLK); #1;

        CS = 1; WE = 0;
        data_drive = 32'b0;

        SIGNED = 0;
        @(negedge CLK); #1;

        if (DATA_BUS !== 32'h0000BEEF) $fatal("HALFWORD READ FAILED: got %h", DATA_BUS);
        $display("HALFWORD READ PASSED: %h", DATA_BUS);

        // --------------------
        // TEST 3: Word write/read
        // --------------------
        CS = 1; WE = 1;
        DATA_ADDR = 20'h34;
        DATA_SIZE = 2'b10; // word
        data_drive = 32'hDEADBEEF;

        @(negedge CLK); #1;

        CS = 1; WE = 0;
        data_drive = 32'b0;

        SIGNED = 0;
        @(negedge CLK); #1;

        if (DATA_BUS !== 32'hDEADBEEF) $fatal("WORD READ FAILED: got %h", DATA_BUS);
        $display("WORD READ PASSED: %h", DATA_BUS);

        // --------------------
        // TEST 4: Sign-extended read
        // --------------------
        // write 8'h80 (negative if signed) into memory and read it signed

        CS = 1; WE = 1;
        DATA_ADDR = 20'h41;
        DATA_SIZE = 2'b00; // byte
        data_drive = 32'h00000080; // 8'b10000000 => -128 in signed

        @(negedge CLK); #1;

        CS = 1; WE = 0;
        data_drive = 32'b0;
        
        SIGNED = 1; // signed read
        @(negedge CLK); #1;

        if (DATA_BUS !== 32'hFFFFFF80) $fatal("SIGNED BYTE READ FAILED: got %h", DATA_BUS);
        $display("SIGNED BYTE READ PASSED: %h", DATA_BUS);

        // --------------------
        // TEST 5: Sign-extended read
        // --------------------
        // write 16'h8123 (negative if signed) into memory and read it signed

        CS = 1; WE = 1;
        DATA_ADDR = 20'h40;
        DATA_SIZE = 2'b01; // halfword
        data_drive = 32'h00008123; 

        @(negedge CLK); #1;

        CS = 1; WE = 0;
        data_drive = 32'b0;
        
        SIGNED = 1; // signed read
        @(negedge CLK); #1;

        if (DATA_BUS !== 32'hFFFF8123) $fatal("SIGNED HALFWORD READ FAILED: got %h", DATA_BUS);
        $display("SIGNED HALFWORD READ PASSED: %h", DATA_BUS);

        // --------------------
        // TEST 6: Instruction fetch
        // --------------------
        // Assume $readmemh loaded 0x12345678 into location 0x50
        // manually write into RAM to simulate this if needed

        uut.RAM[80] = 8'h78; // address 0x50
        uut.RAM[81] = 8'h56;
        uut.RAM[82] = 8'h34;
        uut.RAM[83] = 8'h12;

        INSTR_ADDR = 20'h50;

        @(negedge CLK); @(negedge CLK);

        if (INSTR_BUS !== 32'h12345678) $fatal("INSTRUCTION FETCH FAILED: got %h", INSTR_BUS);
        $display("INSTRUCTION FETCH PASSED: %h", INSTR_BUS);

        $display("All tests passed!");
        $finish;
    end

endmodule
