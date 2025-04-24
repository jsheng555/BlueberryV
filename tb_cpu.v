`timescale 1ns / 1ps

module cpu_tb();
    reg CLK;
    parameter N = 6; // number of clock cycles to test for

    initial begin
        CLK = 0;
        forever #5 CLK = ~CLK;
    end

    cpu CPU(CLK);

    integer i;
    initial begin
        #6; // wait for first rising edge
        for (i = 1 ; i <= N ; i = i + 1) begin
            $display("CYCLE %d", i);
            $display("DE_PC: %x\tDE_IR: %x", CPU.DE_PC, CPU.DE_IR);
            $display("EX_PC: %x\tEX_OP: %x\tEX_RS1: %x\tEX_RS2: %x", CPU.EX_PC, CPU.EX_OP, CPU.EX_RS1, CPU.EX_RS2);
            $display("ME_ALU_RE: %x\tME_BRT: %x", CPU.ME_ALU_RE, CPU.ME_BRT);
            $display("WB_ALU_RE: %x\tWB_MEM_RE: %x", CPU.WB_ALU_RE, CPU.WB_MEM_RE);
            #10;
        end

        $display("\nREGISTER FILE AT END OF PROGRAM");
        for (i = 0 ; i < 32 ; i = i + 1) begin
            $display("Register %d: %x", i, CPU.RF.REG[i]);
        end

        $stop;
    end


endmodule;