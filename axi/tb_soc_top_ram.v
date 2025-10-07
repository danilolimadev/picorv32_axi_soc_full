`timescale 1ns / 1ps

module tb_soc_top_ram;

  // Clock e reset
  reg clk;
  reg resetn;

  // Instância do DUT (Device Under Test)
  soc_top dut (
    .clk(clk),
    .resetn(resetn)
  );

  // Geração de clock: 100MHz (10ns período)
  initial clk = 0;
  always #5 clk = ~clk;

  // Monitoramento de escrita na RAM
  always @(posedge clk) begin
    if (dut.mem_axi_awvalid && dut.mem_axi_awready &&
        dut.mem_axi_wvalid && dut.mem_axi_wready) begin
      $display("[%t] Escrita na RAM: addr = 0x%h, data = 0x%h, wstrb = %b",
               $time, dut.mem_axi_awaddr, dut.mem_axi_wdata, dut.mem_axi_wstrb);
    end
  end

  // Monitoramento de leitura da RAM
  always @(posedge clk) begin
    if (dut.mem_axi_arvalid && dut.mem_axi_arready) begin
      $display("[%t] Leitura solicitada: addr = 0x%h", $time, dut.mem_axi_araddr);
    end
    if (dut.mem_axi_rvalid && dut.mem_axi_rready) begin
      $display("[%t] Leitura concluída: data = 0x%h", $time, dut.mem_axi_rdata);
    end
  end

  // Sequência de reset
  initial begin
    resetn = 0;
    #20;
    resetn = 1;
  end

  // Monitoramento e encerramento
  initial begin
    $display("Iniciando simulação...");
    $dumpfile("tb_soc_top.vcd");      // Arquivo de waveform
    $dumpvars(0, tb_soc_top_ram);         // Dump de todos os sinais

    // Tempo máximo de simulação
    #10000;

    $display("Simulação finalizada.");
  

    $stop;
  end

endmodule

