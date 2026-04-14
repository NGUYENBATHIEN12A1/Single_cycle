module Reg_file(
    input clk,
    input rst,
    input Reg_write,
    input [4:0] rs1, rs2, rd,
    input [31:0] write_data,
    output [31:0] read_data1, read_data2
);

reg [31:0] Registers [31:0];
integer k;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        for (k = 0; k < 32; k = k + 1) begin
            Registers[k] <= 32'b0;
        end
    end else if (Reg_write && rd != 0) begin
        Registers[rd] <= write_data;
    end
end

assign read_data1 = Registers[rs1];
assign read_data2 = Registers[rs2];

endmodule