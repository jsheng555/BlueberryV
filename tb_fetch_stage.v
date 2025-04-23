`timescale 1ns/1ps

module fetch_stage_tb;

    reg CLK;
    reg ME_BRT;
    reg [31:0] ME_ALU_RE;
    wire DE_V;
    wire [31:0] DE_IR;
    wire [15:0] DE_PC;

    fetch_stage uut(
        .CLK(CLK),
        .ME_BRT(ME_BRT),
        .ME_ALU_RE(ME_ALU_RE),
        .DE_V(DE_V),
        .DE_IR(DE_IR),
        .DE_PC(DE_PC)
    );

    // Clock generation
    initial CLK = 0;
    always #5 CLK = ~CLK;

    initial begin
        $display("Starting fetch_stage_tb");

        // Initialize
        ME_BRT = 0;
        ME_ALU_RE = 32'b0;

        // Assume instrMemory has some known program (like DEADBEEF at 0, CAFEBABE at 4, etc.)

        // Wait for first instruction fetch
        #10;
        if (DE_PC !== 16'h0000) $display("FAILED: PC != 0 at cycle 1");
        $display("Cycle 1: PC=%h, IR=%h", DE_PC, DE_IR);

        // PC should now be 4
        #10;
        if (DE_PC !== 16'h0004) $display("FAILED: PC != 4 at cycle 2");
        $display("Cycle 2: PC=%h, IR=%h", DE_PC, DE_IR);

        // Trigger a branch
        ME_BRT = 1;
        ME_ALU_RE = 32'h00001000; // Branch target 0x1000

        #10; // must latch into PC, then latch into decode (2 cycles)
        ME_BRT = 0;
        #10;
        if (DE_PC !== 16'h1000) $display("FAILED: PC != 0x1000 after branch");
        $display("Cycle 3 (branch): PC=%h, IR=%h", DE_PC, DE_IR);


        #10;
        if (DE_PC !== 16'h1004) $display("FAILED: PC != 0x1004 after branch+4");
        $display("Cycle 4: PC=%h, IR=%h", DE_PC, DE_IR);

        $display("Test completed.");
        $finish;
    end

endmodule
