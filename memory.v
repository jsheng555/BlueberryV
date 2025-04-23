module dataMemory(WE, CLK, ADDR, BUS, DATA_SIZE, SIGNED);
    input WE;
    input CLK;
    input [15:0] ADDR;
    inout [31:0] BUS;
    input [1:0] DATA_SIZE; // 00 = byte, 01 = halfword, 10 = word
    input SIGNED; // 0 = unsigned, 1 = signed

    reg [31:0] data_out;
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
    assign BUS = (WE == 1'b1) ? 32'bZ : data_out;
    always @(negedge CLK)
    begin
        // NOTE: This implementation is different from LC-3b.
        // All the rotation logic is built into memory. Just input the address, data, and WE signal.
        if (WE == 1'b1) begin
            case (DATA_SIZE) 
                2'b00: RAM[ADDR] <= BUS[7:0]; // byte store
                2'b01: begin // halfword store
                    RAM[ADDR] <= BUS[7:0];
                    RAM[ADDR+1] <= BUS[15:8];
                end
                2'b10: begin // word store
                    RAM[ADDR] <= BUS[7:0];
                    RAM[ADDR+1] <= BUS[15:8];
                    RAM[ADDR+2] <= BUS[23:16];
                    RAM[ADDR+3] <= BUS[31:24];
                end
                default: $fatal("INVALID DATA SIZE"); 
            endcase
        end

        case (DATA_SIZE)
            2'b00: data_out <= SIGNED ? {{24{RAM[ADDR][7]}}, RAM[ADDR]} : {24'b0, RAM[ADDR]};
            2'b01: data_out <= SIGNED ? {{16{RAM[ADDR+1][7]}}, RAM[ADDR+1], RAM[ADDR]} : {16'b0, RAM[ADDR+1], RAM[ADDR]};
            2'b10: data_out <= {RAM[ADDR+3], RAM[ADDR+2], RAM[ADDR+1], RAM[ADDR]};
            default: $fatal("INVALID DATA SIZE"); 
        endcase
            
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