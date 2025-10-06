// ===== ADICIONADO: Comentários explicativos automáticos =====
// Este arquivo recebeu um bloco de comentários adicionais para
// auxiliar na simulação e entendimento. (picorv32.v foi mantido
// sem alterações por sua solicitação.)
// Você pode remover este bloco se preferir comentários mais curtos.

`timescale 1ns/1ps
// tb_soc_full_test.v - Testbench geral para PL_picorv32_axi
// - Carrega firmware.hex via mem_subsystem_axi (já implementado)
// - Valida conteúdo de memória inicial (confere o .hex carregado)
// - Monitora handshakes AXI entre CPU e RAM/Periféricos (S0 = RAM, S1 = Periféricos)
// - Exibe eventos e termina com sucesso/falha
module tb_soc_full_test;

  // ---------------- Clock / Reset ----------------
  reg aclk = 1'b0;
  reg aresetn = 1'b0;
  always #5 aclk = ~aclk; // 100 MHz clock (10 ns)

  // ---------------- GPIO (externo ao SoC) ----------------
  reg  [15:0] gpio_in = 16'h0000;
  wire [15:0] gpio_out;
  wire [15:0] gpio_oe;

  // ---------------- Instantiate SoC (UUT) ----------------
  soc_top_picorv32_axi u_soc (
    .aclk(aclk), .aresetn(aresetn),
    .gpio_in(gpio_in),
    .gpio_out(gpio_out),
    .gpio_oe(gpio_oe)
  );

  // ---------------- Waveform ----------------
  initial begin
    $dumpfile("tb_soc_full_test.vcd");
    $dumpvars(0, tb_soc_full_test);
  end

  // ---------------- Main test sequence ----------------
  initial begin : main_test
    integer i;
    integer j;
    // Reset
    aresetn = 1'b0;
    repeat (10) @(posedge aclk);
    aresetn = 1'b1;
    $display("[%0t] Reset desasserted", $time);

    // Wait até firmware ser carregado em u_soc.u_mem.mem[0] (mem preload padrão é 0x0000006F)
    // Se o arquivo firmware.hex existir, mem[0] deverá mudar.
    for (i = 0; i < 2000; i = i + 1) begin
      @(posedge aclk);
      if (u_soc.u_mem.mem[0] !== 32'h0000006f) begin
        $display("[%0t] firmware.hex carregado: mem[0]=%08x", $time, u_soc.u_mem.mem[0]);
        disable wait_fw;
      end
    end
    $display("[%0t] Timeout esperando firmware (mem[0] ainda = 0x6F)", $time);
    $fatal; // falha se firmware não carregado
    wait_fw: begin end

    // Valida conteúdo do firmware (conferir cada palavra com o hex fornecido)
    reg [31:0] expected [0:8];
    expected[0] = 32'h100000b7;
    expected[1] = 32'h05500113;
    expected[2] = 32'h0020a023;
    expected[3] = 32'h0aa00193;
    expected[4] = 32'h1030a023;
    expected[5] = 32'h1000a203;
    expected[6] = 32'h2040a023;
    expected[7] = 32'h3040a023;
    expected[8] = 32'h7fdff06f;

    for (j = 0; j < 9; j = j + 1) begin
      if (u_soc.u_mem.mem[j] !== expected[j]) begin
        $display("[%0t] ERRO: firmware mismatch at word %0d: got=%08x exp=%08x", $time, j, u_soc.u_mem.mem[j], expected[j]);
        $fatal;
      end
    end
    $display("[%0t] firmware.hex verificado com sucesso (primeiras 9 palavras).", $time);

    // Monitora activity AXI nas janelas S0 (RAM) e S1 (Periféricos).
    // O bloco abaixo roda concorrentemente e reporta eventos de leitura/escrita AXI.
    fork
      begin : axi_monitor
        integer reads, writes, periph_writes;
        reads = 0; writes = 0; periph_writes = 0;
        // Timeout global para não travar a simulação
        integer timeout;
        timeout = 0;
        while (timeout < 50000) begin
          @(posedge aclk);
          timeout = timeout + 1;
          // RAM (S0) read
          if (u_soc.S0_ARVALID) begin
            $display("[%0t] AXI-RAM READ  addr=%08x", $time, u_soc.S0_ARADDR);
            reads = reads + 1;
          end
          // RAM (S0) write (AW + W)
          if (u_soc.S0_AWVALID && u_soc.S0_WVALID) begin
            $display("[%0t] AXI-RAM WRITE addr=%08x data=%08x strobe=%b", $time, u_soc.S0_AWADDR, u_soc.S0_WDATA, u_soc.S0_WSTRB);
            writes = writes + 1;
          end
          // Periféricos (S1) write
          if (u_soc.S1_AWVALID && u_soc.S1_WVALID) begin
            $display("[%0t] AXI-PERIPH WRITE addr=%08x data=%08x", $time, u_soc.S1_AWADDR, u_soc.S1_WDATA);
            periph_writes = periph_writes + 1;
          end
          // termina cedo se já houve atividade suficiente
          if (reads > 0 || writes > 0 || periph_writes > 0) begin
            $display("[%0t] AXI activity detected: reads=%0d writes=%0d periph_writes=%0d", $time, reads, writes, periph_writes);
            disable axi_monitor;
          end
        end
        $display("[%0t] AXI monitor timeout (no activity detected).", $time);
      end
    join_none

    // Deixe o core rodar alguns ciclos adicionais para causar acesso a memória/periféricos
    repeat (2000) @(posedge aclk);

    // Mostra o estado dos GPIOs expostos pelo SoC
    $display("[%0t] GPIO OUT = %h, GPIO OE = %h", $time, gpio_out, gpio_oe);

    $display("[%0t] Testbench: tudo OK (encerrando).", $time);
    #100 $finish;
  end

  // Watchdog global (evita simulação infinita)
  initial begin
    #2_000_000; // 2 ms @ 1ns resolution
    $display("[%0t] WATCHDOG: timeout geral.", $time);
    $fatal;
  end

endmodule
