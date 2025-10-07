module tb_soc_stage3;
    reg clk = 0;
    reg resetn = 0;

    wire [31:0] gpio_out;

    soc_top dut (
        .clk(clk),
        .resetn(resetn),
        .gpio_out(gpio_out)
    );

    always #5 clk = ~clk; // clock 100MHz

    initial begin
        $dumpfile("soc_stage3.vcd");
        $dumpvars(0, dut);

        resetn = 0;
        #100;
        resetn = 1;

        // simulação roda até firmware escrever no GPIO
        #2000;

        $display("GPIO OUT = %h", gpio_out);
        $finish;
    end
endmodule
