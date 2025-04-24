module dataMemory(WE, CLK, ADDR, DATA_IN, DATA_SIZE, SIGNED, DATA_OUT);
    input WE;
    input CLK;
    input [15:0] ADDR;
    input [31:0] DATA_IN;
    input [1:0] DATA_SIZE; // 00 = byte, 01 = halfword, 10 = word
    input SIGNED; // 0 = unsigned, 1 = signed
    output reg [31:0] DATA_OUT;
    reg [7:0] RAM [0:65535];

    // initialize memory with the data
    integer i;
    initial
    begin
        for (i = 0 ; i < 65536 ; i = i+1) begin
        RAM[i] = 8'h00;
        end
        $readmemh("data.mem", RAM);
    end

    // actual memory logic
    always @(negedge CLK)
    begin
        // NOTE: This implementation is different from LC-3b.
        // All the rotation logic is built into memory. Just input the address, data, and WE signal.
        if (WE == 1'b1) begin
            case (DATA_SIZE) 
                2'b00: RAM[ADDR] <= DATA_IN[7:0]; // byte store
                2'b01: begin // halfword store
                    RAM[ADDR] <= DATA_IN[7:0];
                    RAM[ADDR+1] <= DATA_IN[15:8];
                end
                2'b10: begin // word store
                    RAM[ADDR] <= DATA_IN[7:0];
                    RAM[ADDR+1] <= DATA_IN[15:8];
                    RAM[ADDR+2] <= DATA_IN[23:16];
                    RAM[ADDR+3] <= DATA_IN[31:24];
                end
                // default: $fatal("INVALID DATA SIZE"); 
            endcase
        end else begin
            case (DATA_SIZE)
                2'b00: DATA_OUT <= SIGNED ? {{24{RAM[ADDR][7]}}, RAM[ADDR]} : {24'b0, RAM[ADDR]};
                2'b01: DATA_OUT <= SIGNED ? {{16{RAM[ADDR+1][7]}}, RAM[ADDR+1], RAM[ADDR]} : {16'b0, RAM[ADDR+1], RAM[ADDR]};
                2'b10: DATA_OUT <= {RAM[ADDR+3], RAM[ADDR+2], RAM[ADDR+1], RAM[ADDR]};
                // default: $fatal("INVALID DATA SIZE"); 
            endcase
        end
        // instr_out <= {RAM[INSTR_ADDR+3], RAM[INSTR_ADDR+2], RAM[INSTR_ADDR+1], RAM[INSTR_ADDR]};
    end
endmodule




module instrMemory(CLK, ADDR, INSTR);
    input CLK;
    input [15:0] ADDR;
    output reg [31:0] INSTR;

    reg [7:0] RAM [0:65535];

    // initialize memory with the program
    integer i;
    initial
    begin
        for (i = 0 ; i < 65536 ; i = i+1) begin
        RAM[i] = 8'h00;
        end
        $readmemh("program.mem", RAM);
    end

    // actual memory logic
    always @(negedge CLK)
    begin   
        INSTR <= {RAM[ADDR+3], RAM[ADDR+2], RAM[ADDR+1], RAM[ADDR]};
    end
endmodule