module alu(A, B, opcode, funct3, funct7, result);
    input [31:0] A; 
    input [31:0] B; 
    input [6:0] opcode;
    input [2:0] funct3;
    input [6:0] funct7;
    output reg [31:0] result;

    wire [31:0] sign_extend = {32{A[31]}};

    wire signed [31:0] A_s, B_s;
    assign A_s = A; assign B_s = B;

    always @ (*) begin
        if (opcode == 7'b0110111) result = B; // LUI. B is imm left shifted outside of the ALU.
        else if (opcode == 7'b0010111) result = A + B; // AUIPC. A is PC, B is imm left shifted outside of the ALU.
        else if (opcode == 7'b0000011) result = A + B; // Address generation for loads
        else if (opcode == 7'b0100011) result = A + B; // Address generation for stores
        else if (opcode == 7'b1100011) result = A + B; // Address generation for branches
        else begin
            case (funct3) 
            3'h0: result = (funct7 == 7'h20) ? A - B : A + B;
            3'h4: result = A ^ B;
            3'h6: result = A | B;
            3'h7: result = A & B;
            3'h1: result = A << B[4:0];
            3'h5: result = (funct7 == 7'h20) ? (sign_extend << (32-B[4:0])) | (A >> B[4:0]) : (A >> B[4:0]);
            3'h2: result = (A_s < B_s) ? 1 : 0;
            3'h3: result = (A < B) ? 1 : 0;
            default: result = 32'hDEADBEEF;
            endcase
        end
    end

endmodule