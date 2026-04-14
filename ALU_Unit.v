//ALU_unit
// ALU
module ALU_unit (
    input  [31:0] A, B,
    input  [3:0]  Control_in,
    output reg [31:0] ALU_Result,
    output reg zero
);

always @(*) begin
    case (Control_in)
        4'b0000: begin // AND
            ALU_Result = A & B;
            zero = 0;
        end

        4'b0001: begin // OR
            ALU_Result = A | B;
            zero = 0;
        end

        4'b0010: begin // ADD
            ALU_Result = A + B;
            zero = 0;
        end

        4'b0110: begin // SUB
            ALU_Result = A - B;
            if (A == B)
                zero = 1;
            else
                zero = 0;
        end

        default: begin
            ALU_Result = 32'b0;
            zero = 0;
        end
    endcase
end

endmodule