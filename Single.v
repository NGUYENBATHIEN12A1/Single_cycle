`timescale 1ns / 1ps

// ==========================================
// Generic 2-to-1 Multiplexer
// ==========================================
module Mux2to1 (
    input [31:0] in0, in1,
    input sel,
    output [31:0] out
);
    assign out = (sel == 1'b0) ? in0 : in1;
endmodule

// ==========================================
// Adder Module
// ==========================================
module Adder(
    input [31:0] in_1, in_2,
    output [31:0] Sum_out
);
    assign Sum_out = in_1 + in_2;
endmodule

// ==========================================
// ALU Control Module
// ==========================================
module ALU_Control(
    input [1:0] ALUOp,
    input fun7,
    input [2:0] fun3,
    output reg [3:0] Control_out
);
    always @(*) begin
        case({ALUOp, fun7, fun3})
            6'b00_0_000: Control_out = 4'b0010; // Load/Store (Add)
            6'b01_0_000: Control_out = 4'b0110; // Beq (Sub)
            6'b10_0_000: Control_out = 4'b0010; // R-type Add
            6'b10_1_000: Control_out = 4'b0110; // R-type Sub
            6'b10_0_111: Control_out = 4'b0000; // R-type And
            6'b10_0_110: Control_out = 4'b0001; // R-type Or
            default:     Control_out = 4'b0000;
        endcase 
    end
endmodule

// ==========================================
// ALU Unit Module
// ==========================================
module ALU_unit (
    input  [31:0] A, B,
    input  [3:0]  Control_in,
    output reg [31:0] ALU_Result,
    output reg zero
);
    always @(*) begin 
        case (Control_in)
            4'b0000: ALU_Result = A & B;      // AND
            4'b0001: ALU_Result = A | B;      // OR
            4'b0010: ALU_Result = A + B;      // ADD
            4'b0110: ALU_Result = A - B;      // SUB
            default: ALU_Result = 32'b0;
        endcase
        zero = (ALU_Result == 32'b0) ? 1'b1 : 1'b0;
    end
endmodule

// ==========================================
// Control Unit Module
// ==========================================
module Control_Unit(
    input [6:0] instruction,
    output reg Branch, MemRead, MemtoReg, MemWrite, ALUSrc, RegWrite,
    output reg [1:0] ALUOp
);
    always @(*) begin
        case(instruction)
            7'b0110011 : {ALUSrc, MemtoReg, RegWrite, MemRead, MemWrite, Branch, ALUOp} = 8'b00100010; // R-type
            7'b0000011 : {ALUSrc, MemtoReg, RegWrite, MemRead, MemWrite, Branch, ALUOp} = 8'b11110000; // Load
            7'b0100011 : {ALUSrc, MemtoReg, RegWrite, MemRead, MemWrite, Branch, ALUOp} = 8'b10001000; // Store
            7'b1100011 : {ALUSrc, MemtoReg, RegWrite, MemRead, MemWrite, Branch, ALUOp} = 8'b00000101; // Branch
            7'b0010011 : {ALUSrc, MemtoReg, RegWrite, MemRead, MemWrite, Branch, ALUOp} = 8'b10100000; // I-type (addi)
            default    : {ALUSrc, MemtoReg, RegWrite, MemRead, MemWrite, Branch, ALUOp} = 8'b00000000;
        endcase
    end
endmodule

// ==========================================
// Data Memory Module
// ==========================================
module Data_Memory(
    input clk, reset, MemWrite, MemRead,
    input [31:0] address, Write_data,
    output [31:0] MemData_out
);
    reg [31:0] D_Memory[63:0];
    integer k;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            for (k = 0; k < 64; k = k + 1) D_Memory[k] <= 32'b0;
        end 
        else if (MemWrite) begin
            D_Memory[address >> 2] <= Write_data;
        end 
    end
    assign MemData_out = (MemRead) ? D_Memory[address >> 2] : 32'b0;
endmodule

// ==========================================
// Immediate Generator Module
// ==========================================
module ImmGen(
    input [6:0] Opcode,
    input [31:0] instruction,
    output reg [31:0] ImmExt
);
    always @(*) begin 
        case (Opcode)
            7'b0000011, 7'b0010011, 7'b1100111: // I-type
                ImmExt = {{20{instruction[31]}}, instruction[31:20]};
            7'b0100011: // S-type 
                ImmExt = {{20{instruction[31]}}, instruction[31:25], instruction[11:7]};
            7'b1100011: // B-type 
                ImmExt = {{19{instruction[31]}}, instruction[31], instruction[7], instruction[30:25], instruction[11:8], 1'b0};
            7'b0110111, 7'b0010111: // U-type
                ImmExt = {instruction[31:12], 12'b0};
            7'b1101111: // J-type
                ImmExt = {{11{instruction[31]}}, instruction[31], instruction[19:12], instruction[20], instruction[30:21], 1'b0};
            default: ImmExt = 32'b0;
        endcase
    end
endmodule

// ==========================================
// Instruction Memory Module
// ==========================================
module Instruction_Mem( 
    input [31:0] read_address,
    output [31:0] instruction_out
);
    reg [31:0] Imen [63:0];
    initial begin
        $readmemh("mem.dump", Imen);
    end
    assign instruction_out = Imen[read_address >> 2];
endmodule

// ==========================================
// Program Counter & PCplus4
// ==========================================
module Program_Counter( 
    input clk, rst,
    input [31:0] PC_in,
    output reg [31:0] PC_out
);
    always @(posedge clk or posedge rst) begin 
        if (rst) PC_out <= 32'b0;
        else     PC_out <= PC_in;
    end
endmodule

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
    input clk, rst, Reg_write,
    input [4:0] rs1, rs2, rd,
    input [31:0] write_data,
    output [31:0] read_data1, read_data2
);
    reg [31:0] Registers [31:0];
    integer k;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (k = 0; k < 32; k = k + 1) Registers[k] <= 32'b0;
        end 
        else if (Reg_write && rd != 5'b0) begin
            Registers[rd] <= write_data;
        end 
    end
    assign read_data1 = Registers[rs1];
    assign read_data2 = Registers[rs2];
endmodule

// ==========================================
// Top Module 
// ==========================================
module top(input clk, reset);
    wire [31:0] PC_top, instruction_top, Rd1_top, Rd2_top, ImmExt_top, ALU_B_top;
    wire [31:0] Branch_Addr_top, NextPC_top, PCplus4_top, ALU_Result_top, Mem_data_top, WriteBack_top;
    wire Regwrite_top, ALUSrc_top, zero_top, branch_top, PCSrc_top, MemtoReg_top, MemWrite_top, MemRead_top;
    wire [1:0] ALUOp_top;
    wire [3:0] Control_top;

    Program_Counter PC_inst (.clk(clk), .rst(reset), .PC_in(NextPC_top), .PC_out(PC_top));
    PCplus4 PC4_inst (.fromPC(PC_top), .NextoPC(PCplus4_top));
    Instruction_Mem IM_inst (.read_address(PC_top), .instruction_out(instruction_top));
    
    Reg_file RF_inst (
        .clk(clk), .rst(reset), .Reg_write(Regwrite_top),
        .rs1(instruction_top[19:15]), .rs2(instruction_top[24:20]), .rd(instruction_top[11:7]),
        .write_data(WriteBack_top), .read_data1(Rd1_top), .read_data2(Rd2_top)
    );

    ImmGen IG_inst (.Opcode(instruction_top[6:0]), .instruction(instruction_top), .ImmExt(ImmExt_top));
    
    Control_Unit CU_inst (
        .instruction(instruction_top[6:0]), .Branch(branch_top), .MemRead(MemRead_top),
        .MemtoReg(MemtoReg_top), .ALUOp(ALUOp_top), .MemWrite(MemWrite_top),
        .ALUSrc(ALUSrc_top), .RegWrite(Regwrite_top)
    );

    ALU_Control AC_inst (.ALUOp(ALUOp_top), .fun7(instruction_top[30]), .fun3(instruction_top[14:12]), .Control_out(Control_top));
    
    Mux2to1 ALU_in_Mux (.in0(Rd2_top), .in1(ImmExt_top), .sel(ALUSrc_top), .out(ALU_B_top));
    
    ALU_unit ALU_inst (.A(Rd1_top), .B(ALU_B_top), .Control_in(Control_top), .ALU_Result(ALU_Result_top), .zero(zero_top));

    Adder Branch_Adder (.in_1(PC_top), .in_2(ImmExt_top), .Sum_out(Branch_Addr_top));

    assign PCSrc_top = branch_top & zero_top;
    Mux2to1 PC_Mux (.in0(PCplus4_top), .in1(Branch_Addr_top), .sel(PCSrc_top), .out(NextPC_top));

    Data_Memory DM_inst (
        .clk(clk), .reset(reset), .MemWrite(MemWrite_top), .MemRead(MemRead_top),
        .address(ALU_Result_top), .Write_data(Rd2_top), .MemData_out(Mem_data_top)
    );

    Mux2to1 WB_Mux (.in0(ALU_Result_top), .in1(Mem_data_top), .sel(MemtoReg_top), .out(WriteBack_top));

endmodule

// ==========================================
// Testbench Module 
// ==========================================
module tb_top;
    reg clk, reset;

    top uut (.clk(clk), .reset(reset));

    initial begin 
        clk = 0;
        reset = 1;
        #15 reset = 0;
        
        // Theo dõi một số tín hiệu quan trọng
        $monitor("Time=%0t | PC=%h | Inst=%h | ALU_Res=%h | WB=%h", 
                 $time, uut.PC_top, uut.instruction_top, uut.ALU_Result_top, uut.WriteBack_top);
        
        #500 $finish;
    end

    always #5 clk = ~clk;

    // Xuất file sóng để xem trên GTKWave
    initial begin
        $dumpfile("riscv_sim.vcd");
        $dumpvars(0, tb_top);
    end
endmodule
