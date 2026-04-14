//RISC-V
// ==========================================
// Adder Module
// ==========================================
// Adder 
module Adder(in_1, in_2, Sum_out);

input [31:0] in_1, in_2;
output [31:0] Sum_out;
assign Sum_out = in_1 + in_2;

endmodule

// ==========================================
// ALU Control Module
// ==========================================
// ALU Control 
module ALU_Control(ALUOp, fun7, fun3, Control_out);
input fun7;
input [2:0] fun3;
input [1:0] ALUOp;
output reg [3:0] Control_out;
always @(*) 
begin
    case({ALUOp, fun7, fun3})
        6'b00_0_000: Control_out <= 4'b0010;
        6'b01_0_000: Control_out <= 4'b0110; 
        6'b10_0_000: Control_out <= 4'b0010;
        6'b10_1_000: Control_out <= 4'b0110;
        6'b10_0_111: Control_out <= 4'b0000;
        6'b10_0_110: Control_out <= 4'b0001;
    endcase 
end

endmodule

// ==========================================
// ALU Unit Module
// ==========================================
// ALU_unit 
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

// ==========================================
// AND Logic Module
// ==========================================
// And Logic 
module AND_logic(branch, zero, and_out);
input branch, zero;
output and_out;

assign and_out = branch & zero;
endmodule

// ==========================================
// Control Unit Module
// ==========================================
// Control_Unit 
module Control_Unit(instruction, Branch, MemRead, MemtoReg, ALUOp, MemWrite, ALUSrc, RegWrite);

input [6:0] instruction;
output reg Branch, MemRead, MemtoReg, MemWrite, ALUSrc, RegWrite;
output reg [1:0] ALUOp;

always @(*) begin
    case(instruction)

        // R-type
        7'b0110011 : {ALUSrc, MemtoReg, RegWrite, MemRead, MemWrite, Branch, ALUOp} <= 8'b00100010;
        // Load (lw) 
        7'b0000011 : {ALUSrc, MemtoReg, RegWrite, MemRead, MemWrite, Branch, ALUOp} <= 8'b11110000;
        // Store (sw) 
        7'b0100011 : {ALUSrc, MemtoReg, RegWrite, MemRead, MemWrite, Branch, ALUOp} <= 8'b10001000;
        // Branch (beq) 
        7'b1100011 : {ALUSrc, MemtoReg, RegWrite, MemRead, MemWrite, Branch, ALUOp} <= 8'b00000101;
        // I-type (addi)
        7'b0010011 : {ALUSrc, MemtoReg, RegWrite, MemRead, MemWrite, Branch, ALUOp} <= 8'b10100000;
        default    : {ALUSrc, MemtoReg, RegWrite, MemRead, MemWrite, Branch, ALUOp} <= 8'b00000000;
    endcase
end

endmodule

// ==========================================
// Data Memory Module
// ==========================================
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

// ==========================================
// Immediate Generator Module
// ==========================================
// Immediate Generator 
module ImmGen(
    input  [6:0]  Opcode,
    input  [31:0] instruction,
    output reg [31:0] ImmExt
);
always @(*) begin 
    case (Opcode)
        // I-type
        7'b0000011,7'b0010011,7'b1100111: ImmExt = {{20{instruction[31]}}, instruction[31:20]};
        // S-type 
        7'b0100011: ImmExt = {{20{instruction[31]}}, instruction[31:25], instruction[11:7]};
        // B-type 
        7'b1100011: ImmExt = {{19{instruction[31]}}, instruction[31],instruction[30:25], instruction[11:8], 1'b0};
        // U-type (lui, auipc) 
        7'b0110111,7'b0010111:ImmExt = {instruction[31:12], 12'b0};
        // J-type (jal) 
        7'b1101111:ImmExt = {{11{instruction[31]}}, instruction[31],instruction[19:12], instruction[20],instruction[30:21], 1'b0};
        default: 
            ImmExt = 32'b0;
    endcase
end

endmodule

// ==========================================
// Instruction Memory Module
// ==========================================
// ==========================================
// Instruction Memory Module
// ==========================================
module Intruction_Mem( 
    input clk,
    input rst,
    input [31:0] read_addess,
    output [31:0] intruction_out // Bỏ 'reg' để sử dụng gán liên tục (assign)
);

reg [31:0] Imen[63:0]; // [cite: 38]

// Nạp dữ liệu từ file mem.dump vào bộ nhớ khi bắt đầu mô phỏng
initial begin
    $readmemh("mem.dump", Imen);
end

// Đọc lệnh (Tổ hợp - Combinational Read)
// Lưu ý: PC của bạn tăng 4 (byte addressing), nhưng mỗi ô nhớ trong Imen chứa 1 word (32-bit).
// Do đó, ta cần dịch phải 2 bit (chia 4) để trỏ đúng vị trí index (PC=0 -> Imen[0], PC=4 -> Imen[1]).
assign intruction_out = Imen[read_addess >> 2];

endmodule

// ==========================================
// Multiplexers
// ==========================================
// Mutiplexer 
module mux1(
    input sell1,
    input [31:0] A1,B1,
    output [31:0] mux1_out
);
assign mux1_out = (sell1==1'b0) ? A1 :B1; 
endmodule

module mux2(
    input sell2,
    input [31:0] A2,B2,
    output [31:0] mux2_out
);
assign mux2_out = (sell2==1'b0) ? A2 :B2; 
endmodule

module mux3(
    input sell3,
    input [31:0] A3,B3,
    output [31:0] mux3_out
);
assign mux3_out = (sell3==1'b0) ? A3 :B3; 
endmodule

// ==========================================
// Program Counter Module
// ==========================================
module Program_Counter( 
    input clk,
    input rst,
    input [31:0] PC_in,
    output reg [31:0] PC_out
);
always @(posedge clk or posedge rst) begin 
    if (rst) begin
        PC_out <= 32'b0;
    end else begin 
        PC_out <= PC_in;
    end
end

endmodule
// ==========================================
// PCplus4 Module 
// ==========================================
module PCplus4(
    input [31:0] fromPC,
    output [31:0] NextoPC
);
assign NextoPC = fromPC + 4;
endmodule 

// ==========================================
// Register File Module 
// ==========================================
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

// ==========================================
// Top Module 
// ==========================================
module top(clk, reset);
input clk, reset;

// Đã sửa lỗi đánh máy Rd1_top.Rd2_top thành Rd1_top, Rd2_top 
wire [31:0] PC_top, instruction_top, Rd1_top, Rd2_top, ImmExt_top, mux1_top, Sum_out_top, NextoPC_top, PCin_top, address_top, Mem_data_top;
wire Regwrite_top, ALU_src_top, zero_top, branch_top, sel2_top, MemtoReg_top, MemWrite_top, MemRead_top, WriteBack_top;
wire [1:0] ALUOp_top;
wire [3:0] Control_top;

// Program Counter 
Program_Counter PC(.clk(clk),.rst(reset),.PC_in(PCin_top),.PC_out(PC_top));

// PC Adder
PCplus4 PC_Adder(.fromPC(PC_top),.NextoPC(NextoPC_top));

// Instruction Memory
Intruction_Mem Inst_Memory(.clk(clk),.rst(reset),.read_addess(PC_top),.intruction_out(instruction_top));

// Register File
Reg_file Reg_File_inst(.clk(clk),.rst(reset),.Reg_write(Regwrite_top),.rs1(instruction_top[19:15]),.rs2(instruction_top[24:20]),.rd(instruction_top[11:7]),.write_data(WriteBack_top),.read_data1(Rd1_top),.read_data2(Rd2_top));

// Immediate Generator 
ImmGen ImmGen_inst (.Opcode(instruction_top[6:0]),.instruction(instruction_top),.ImmExt(ImmExt_top));

// Control Unit
Control_Unit Control_Unit_inst (.instruction(instruction_top[6:0]),.Branch(branch_top),.MemRead(MemRead_top),.MemtoReg(MemtoReg_top),.ALUOp(ALUOp_top),.MemWrite(MemWrite_top),.ALUSrc(ALU_src_top),.RegWrite(Regwrite_top));

// ALU Control
ALU_Control ALU_Control_inst (.ALUOp(ALUOp_top),.fun7(instruction_top[30]),.fun3(instruction_top[14:12]),.Control_out(Control_top));

// ALU
ALU_unit ALU(.A(Rd1_top), .B(mux1_top),.Control_in(Control_top),.ALU_Result(address_top),.zero(zero_top));

// ALU mux (Mux1) 
mux1 ALU_mux(.sell1(ALU_src_top),.A1(Rd2_top),.B1(ImmExt_top),.mux1_out(mux1_top));

// Adder
Adder Adder_inst(.in_1(PC_top), .in_2(ImmExt_top), .Sum_out(Sum_out_top));

// And logic
AND_logic AND_inst(.branch(branch_top), .zero(zero_top), .and_out(sel2_top));

// Adder Mux (Mux2)
mux2 Adder_mux(.sell2(sel2_top),.A2(NextoPC_top),.B2(Sum_out_top),.mux2_out(PCin_top));

// Data memory (Đã thêm tên instance DM_inst) 
Data_Memory DM_inst(.clk(clk), .reset(reset), .MemWrite(MemWrite_top), .MemRead(MemRead_top), .read_address(address_top), .Write_data(Rd2_top), .MemData_out(Mem_data_top));

// Writeback Mux (Mux3) (Đã thêm tên instance WB_mux)
mux3 WB_mux(.sell3(MemtoReg_top),.A3(address_top),.B3(Mem_data_top),.mux3_out(WriteBack_top));

endmodule

// ==========================================
// Testbench Module 
// ==========================================
module tb_top;
reg clk, reset;

    // Instantiate DUT (Device Under Test)
    top uut (
        .clk(clk),
        .reset(reset)
    );

    initial begin 
        clk = 0;
        reset = 1;
        #5  reset = 0;
        #400; 

        $finish;
    end

    // Clock generation (chu kỳ 10 time units)
    always begin
        #5 clk = ~clk;
    end 

endmodule