//testbench
// Testbench
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