//Mutiplexer
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