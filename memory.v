module memory(CS, WE, CLK, INSTR_ADDR, DATA_ADDR, INSTR_BUS, DATA_BUS, DATA_SIZE, SIGNED);
    input CS;
    input WE;
    input CLK;
    input [19:0] DATA_ADDR, INSTR_ADDR;
    input [1:0] DATA_SIZE; // 00 = byte, 01 = halfword, 10 = word
    input SIGNED; // 0 = unsigned, 1 = signed
    inout [31:0] DATA_BUS;
    output [31:0] INSTR_BUS;

    reg [31:0] data_out;
    reg [31:0] instr_out;
    reg [7:0] RAM [0:1048575];

    // initialize memory with the program
    integer i;
    initial
    begin
        for (i = 0 ; i < 1048576 ; i = i+1) begin
        RAM[i] = 8'h00;
        end
        $readmemh("program.mem", RAM);
    end

    // actual memory logic
    assign DATA_BUS = ((CS == 1'b0) || (WE == 1'b1)) ? 32'bZ : data_out;
    assign INSTR_BUS = instr_out;
    always @(negedge CLK)
    begin
        // NOTE: This implementation is different from LC-3b.
        // All the rotation logic is built into memory. Just input the address, data, and WE signal.
        if (CS == 1'b1 && WE == 1'b1) begin
            case (DATA_SIZE) 
                2'b00: RAM[DATA_ADDR] <= DATA_BUS[7:0]; // byte store
                2'b01: begin // halfword store
                    RAM[DATA_ADDR] <= DATA_BUS[7:0];
                    RAM[DATA_ADDR+1] <= DATA_BUS[15:8];
                end
                2'b10: begin // word store
                    RAM[DATA_ADDR] <= DATA_BUS[7:0];
                    RAM[DATA_ADDR+1] <= DATA_BUS[15:8];
                    RAM[DATA_ADDR+2] <= DATA_BUS[23:16];
                    RAM[DATA_ADDR+3] <= DATA_BUS[31:24];
                end
                default: $display("INVALID DATA SIZE"); 
            endcase
        end

        case (DATA_SIZE)
            2'b00: data_out <= SIGNED ? {{24{RAM[DATA_ADDR][7]}}, RAM[DATA_ADDR]} : {24'b0, RAM[DATA_ADDR]};
            2'b01: data_out <= SIGNED ? {{16{RAM[DATA_ADDR+1][7]}}, RAM[DATA_ADDR+1], RAM[DATA_ADDR]} : {16'b0, RAM[DATA_ADDR+1], RAM[DATA_ADDR]};
            2'b10: data_out <= {RAM[DATA_ADDR+3], RAM[DATA_ADDR+2], RAM[DATA_ADDR+1], RAM[DATA_ADDR]};
            default: data_out <= 32'hDEADBEEF; // invalid
        endcase
            
        instr_out <= {RAM[INSTR_ADDR+3], RAM[INSTR_ADDR+2], RAM[INSTR_ADDR+1], RAM[INSTR_ADDR]};
    end
endmodule