// Data Memory
module Data_Memory(clk, reset, MemWrite, MemRead, read_address, Write_data, MemData_out);
input clk, reset, MemWrite, MemRead;
input [31:0] read_address, Write_data;
output [31:0] MemData_out;
integer k;
reg [31:0] D_Memory[63:0];
always @(posedge clk or posedge reset)
begin
    if (reset)
    begin
        for (k = 0; k < 64; k = k + 1) begin
            D_Memory[k] <= 32'b00;
        end
    end
    else if (MemWrite) begin
        D_Memory[read_address] <= Write_data;
    end
end
assign MemData_out = (MemRead) ? D_Memory[read_address] : 32'b00;
endmodule