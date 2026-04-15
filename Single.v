// RISC-V Single Cycle Processor - Full Fixed Version

module Adder(input [31:0] in_1, in_2, output [31:0] Sum_out);
    assign Sum_out = in_1 + in_2;
endmodule

module ALU_Control(input [1:0] ALUOp, input fun7, input [2:0] fun3, output reg [3:0] Control_out);
    always @(*) begin
        case({ALUOp, fun7, fun3})
            6'b00_0_000: Control_out <= 4'b0010; // LW, SW
            6'b01_0_000: Control_out <= 4'b0110; // BEQ
            6'b10_0_000: Control_out <= 4'b0010; // ADD
            6'b10_1_000: Control_out <= 4'b0110; // SUB
            6'b10_0_111: Control_out <= 4'b0000; // AND
            6'b10_0_110: Control_out <= 4'b0001; // OR
            default:     Control_out <= 4'b0000;
        endcase
    end
endmodule

module ALU_unit (input [31:0] A, B, input [3:0] Control_in, output reg [31:0] ALU_Result, output reg zero);
    always @(*) begin
        case (Control_in)
            4'b0000: begin ALU_Result = A & B; zero = 0; end
            4'b0001: begin ALU_Result = A | B; zero = 0; end
            4'b0010: begin ALU_Result = A + B; zero = 0; end
            4'b0110: begin ALU_Result = A - B; zero = (A == B); end
            default: begin ALU_Result = 32'b0; zero = 0; end
        endcase
    end
endmodule

module Control_Unit(input [6:0] instruction, output reg Branch, MemRead, MemtoReg, MemWrite, ALUSrc, RegWrite, output reg [1:0] ALUOp);
    always @(*) begin
        case(instruction)
            7'b0110011 : {ALUSrc, MemtoReg, RegWrite, MemRead, MemWrite, Branch, ALUOp} <= 8'b00100010;
            7'b0000011 : {ALUSrc, MemtoReg, RegWrite, MemRead, MemWrite, Branch, ALUOp} <= 8'b11110000;
            7'b0100011 : {ALUSrc, MemtoReg, RegWrite, MemRead, MemWrite, Branch, ALUOp} <= 8'b10001000;
            7'b1100011 : {ALUSrc, MemtoReg, RegWrite, MemRead, MemWrite, Branch, ALUOp} <= 8'b00000101;
            7'b0010011 : {ALUSrc, MemtoReg, RegWrite, MemRead, MemWrite, Branch, ALUOp} <= 8'b10100000;
            default    : {ALUSrc, MemtoReg, RegWrite, MemRead, MemWrite, Branch, ALUOp} <= 8'b00000000;
        endcase
    end
endmodule

module Data_Memory(input clk, reset, MemWrite, MemRead, input [31:0] read_address, Write_data, output [31:0] MemData_out);
    reg [31:0] D_Memory [0:63];
    integer k;
    always @(posedge clk or posedge reset) begin
        if (reset) for (k = 0; k < 64; k = k + 1) D_Memory[k] <= 32'b0;
        else if (MemWrite) D_Memory[read_address >> 2] <= Write_data;
    end
    assign MemData_out = (MemRead) ? D_Memory[read_address >> 2] : 32'b0;
endmodule

module ImmGen(input [6:0] Opcode, input [31:0] instruction, output reg [31:0] ImmExt);
    always @(*) begin
        case (Opcode)
            7'b0000011, 7'b0010011: ImmExt = {{20{instruction[31]}}, instruction[31:20]};
            7'b0100011: ImmExt = {{20{instruction[31]}}, instruction[31:25], instruction[11:7]};
            7'b1100011: ImmExt = {{19{instruction[31]}}, instruction[31], instruction[7], instruction[30:25], instruction[11:8], 1'b0};
            default: ImmExt = 32'b0;
        endcase
    end
endmodule

module Intruction_Mem(input [31:0] read_address, output [31:0] instruction_out);
    reg [31:0] Imen [0:63];
    initial $readmemh("mem.dump", Imen);
    assign instruction_out = Imen[read_address >> 2];
endmodule

module Reg_file(input clk, rst, Reg_write, input [4:0] rs1, rs2, rd, input [31:0] write_data, output [31:0] rd1, rd2);
    reg [31:0] Registers [0:31];
    integer k;
    always @(posedge clk or posedge rst) begin
        if (rst) for (k = 0; k < 32; k = k + 1) Registers[k] <= 32'b0;
        else if (Reg_write && rd != 0) Registers[rd] <= write_data;
    end
    assign rd1 = Registers[rs1];
    assign rd2 = Registers[rs2];
endmodule

module Program_Counter(input clk, rst, input [31:0] PC_in, output reg [31:0] PC_out);
    always @(posedge clk or posedge rst) begin
        if (rst) PC_out <= 32'b0;
        else PC_out <= PC_in;
    end
endmodule

module top(input clk, reset);
    wire [31:0] PC_top, inst, rd1, rd2, imm, alu_b, alu_res, pc_plus4, pc_target, pc_next, mem_out, wb_data;
    wire reg_w, alu_src, zero, branch, mem_to_reg, mem_w, mem_r;
    wire [1:0] alu_op;
    wire [3:0] alu_ctrl;

    Program_Counter PC_inst(clk, reset, pc_next, PC_top);
    Intruction_Mem IM(PC_top, inst);
    Control_Unit CU(inst[6:0], branch, mem_r, mem_to_reg, mem_w, alu_src, reg_w, alu_op);
    Reg_file RF(clk, reset, reg_w, inst[19:15], inst[24:20], inst[11:7], wb_data, rd1, rd2);
    ImmGen IG(inst[6:0], inst, imm);
    ALU_Control AC(alu_op, inst[30], inst[14:12], alu_ctrl);
    
    assign alu_b = alu_src ? imm : rd2;
    ALU_unit ALU(rd1, alu_b, alu_ctrl, alu_res, zero);
    
    assign pc_plus4 = PC_top + 4;
    assign pc_target = PC_top + imm;
    assign pc_next = (branch & zero) ? pc_target : pc_plus4;
    
    Data_Memory DM(clk, reset, mem_w, mem_r, alu_res, rd2, mem_out);
    assign wb_data = mem_to_reg ? mem_out : alu_res;
endmodule

module tb_top;
    reg clk, reset;
    integer i;

    top uut (clk, reset);

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, tb_top);
        clk = 0; reset = 1; #10 reset = 0;
        #200 $finish;
    end

    always #5 clk = ~clk;

    always @(posedge clk) begin
        if (!reset) begin
            $display("\n>>> CHU KY: %0d | PC: %h | Lenh: %h <<<", ($time/10), uut.PC_top, uut.inst);
            
            $display("--- REGISTERS ---");
            for (i = 0; i < 32; i = i + 4) begin
                $display("x%0d: %h | x%0d: %h | x%0d: %h | x%0d: %h", 
                         i,   uut.RF.Registers[i], 
                         i+1, uut.RF.Registers[i+1], 
                         i+2, uut.RF.Registers[i+2], 
                         i+3, uut.RF.Registers[i+3]);
            end

            $display("--- DATA MEMORY ---");
            $display("M[0]: %h | M[1]: %h | M[2]: %h | M[3]: %h", uut.DM.D_Memory[0], uut.DM.D_Memory[1], uut.DM.D_Memory[2], uut.DM.D_Memory[3]);
            $display("------------------------------------------------------------------");
        end
    end
endmodule
