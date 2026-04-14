//top module
module top(clk, reset);
input clk, reset;
wire [31:0] PC_top, instruction_top,Rd1_top.Rd2_top,ImmExt_top,mux1_top,Sum_out_top,NextoPC_top,PCin_top,address_top,Mem_data_top;
wire Regwrite_top,ALU_src_top,zero_top,branch_top,sel2_top,MemtoReg_top,MemWrite_top,MemRead_top,WriteBack_top;
wire [1:0]ALUOp_top;
wire [3:0] Control_top;
// Program Counter
Program_counter PC(.clk(clk),.reset(reset),.PC_in(PCin_top),.PC_out(PC_top));
// PC Adder
PCplus4 PC_Adder(.fromPC(PC_top),.NextoPC(NextoPC_top));
// Instruction Memory
Instruction_Memory Inst_Memory(.clk(clk),.reset(reset),.read_address(PC_top),.instruction_out(instruction_top));
// Register File
Reg_File Reg_File(.clk(clk),.reset(reset),.RegWrite(Regwrite_top),.Rs1(instruction_top[19:15]),.Rs2(instruction_top[24:20]),.Rd(instruction_top[11:7]),.Write_data(WriteBack_top),.read_data1(Rd1_top),.read_data2(Rd2_top));
//Imm Gen
// Immediate Generator
ImmGen ImmGen_inst (.Opcode(instruction_top[6:0]),.instruction(instruction_top),.ImmExt(ImmExt_top));
// Control Unit
Control_Unit Control_Unit_inst (.instruction(instruction_top[6:0]),.Branch(branch_top),.MemRead(MemRead_top),.MemtoReg(MemtoReg_top),.ALUOp(ALUOp_top),.MemWrite(MemWrite_top),.ALUSrc(ALU_src_top),.RegWrite(RegWrite_top));
// ALU Control
ALU_Control ALU_Control_inst (.ALUOp(ALUOp_top),.fun7(instruction_top[30]),.fun3(instruction_top[14:12]),.Control_out(Control_top));
//ALU
ALU_unit ALU(.A(Rd1_top), .B(mux1_top),.Control_in(Control_top),.ALU_Result(address_top),.zero(zero_top));
//ALU mux
Mux1 ALU_mux(.sel1(ALU_src_top),.A1(Rd2_top),B1(ImmExt_top),Mux_out(mux1_top));
//Adder
Adder Adder(.in_1(PC_top), .in_2(ImmExt_top), .Sum_out(Sum_out_top));
//And logic
AND_logic AND(.branch(branch_top), .zero(zero_top), .and_out(sel2_top));

mux2 Adder_mux(.sell2(sel2_top),.A2(NextoPC_top),.B2(Sum_out_top),.mux2_out(PCin_top));

//Data memory
Data_Memory(.clk(clk), .reset(reset), .MemWrite(MemWrite_top), .MemRead(MemRead_top), .read_address(address_top), .Write_data(Rd2_top), .MemData_out(Mem_data_top));

mux3 (.sell3(MemtoReg_top),.A3(address_top),.B3(Mem_data_top),.mux3_out(WriteBack_top));

endmodule