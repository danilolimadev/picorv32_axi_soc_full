`timescale 1ns / 1ps

module tb_soc_top;

  // Clock e reset
  reg clk;
  reg resetn;

  // Instância do DUT (Device Under Test)
  soc_top dut (
    .clk(clk),
    .resetn(resetn)
  );

  // Geração de clock: 10ns período (100MHz)
  initial clk = 0;
  always #5 clk = ~clk;

  // Sequência de reset
  initial begin
    resetn = 0;
    #20;
    resetn = 1;
  end

  // Estímulos básicos
  initial begin
    // Inicialização de sinais simulados
    dut.mem_axi_awready = 1;
    dut.mem_axi_wready  = 1;
    dut.mem_axi_bvalid  = 0;
    dut.mem_axi_arready = 1;
    dut.mem_axi_rvalid  = 0;
    dut.mem_axi_rdata   = 32'hDEADBEEF;

    dut.pcpi_wr    = 0;
    dut.pcpi_rd    = 32'h00000000;
    dut.pcpi_wait  = 0;
    dut.pcpi_ready = 0;

    dut.irq = 32'h00000000;

    // Espera alguns ciclos
    #100;

    // Simula uma interrupção
    dut.irq = 32'h00000001;
    #20;
    dut.irq = 32'h00000000;

    // Simula resposta de leitura
    dut.mem_axi_rvalid = 1;
    #10;
    dut.mem_axi_rvalid = 0;

    #200;
    $stop;
  end

endmodule
