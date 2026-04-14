module Intruction_Mem(
    input clk,
    input rst,
    input [31:0] read_addess,
    output reg [31:0] intruction_out
);

reg [31:0] Imen[63:0];
integer k;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        for (k = 0; k < 64; k = k + 1) begin
            Imen[k] <= 32'b0;
        end
    end else begin
        intruction_out <= Imen[read_addess[5:0]];
    end
end

endmodule