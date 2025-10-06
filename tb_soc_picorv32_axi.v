// ===== ADICIONADO: Comentários explicativos automáticos =====
// Este arquivo recebeu um bloco de comentários adicionais para
// auxiliar na simulação e entendimento. (picorv32.v foi mantido
// sem alterações por sua solicitação.)
// Você pode remover este bloco se preferir comentários mais curtos.

`timescale 1ns/1ps

module tb_soc_picorv32_axi;

  // ---------------- Clock / Reset ----------------
  reg aclk   = 1'b0;
  reg aresetn = 1'b0;

  // Clock 100 MHz (10 ns)
  always #5 aclk = ~aclk;

  // ---------------- GPIO ----------------
  wire [15:0] gpio_in;
  wire [15:0] gpio_out;
  wire [15:0] gpio_oe;

  // Amarre entrada para teste
  assign gpio_in = 16'hA5A5;

  // ---------------- DUT ----------------
  wire cpu_trap;

  soc_top_picorv32_axi dut (
    .aclk    (aclk),
    .aresetn (aresetn),
    .gpio_in (gpio_in),
    .gpio_out(gpio_out),
    .gpio_oe (gpio_oe),
    .cpu_trap(cpu_trap)
  );

  // ---------------- Monitores hierárquicos do master AXI ----------------
  // (estes sinais existem no TOP refeitos; ajuste os nomes se estiverem diferentes)
  wire        m_arvalid = dut.M_ARVALID;
  wire        m_arready = dut.M_ARREADY;
  wire [31:0] m_araddr  = dut.M_ARADDR;
  wire        m_rvalid  = dut.M_RVALID;
  wire [31:0] m_rdata   = dut.M_RDATA;

  // ---------------- Variáveis de controle (declaradas no escopo do módulo) ----------------
  integer cycles;
  reg saw_read;
  reg saw_trap;

  // ---------------- Estímulo / Watchdog ----------------
  initial begin
    $display("[%0t] TB(full) start", $time);

    // Reset síncrono: segura por ~95 ns
    aresetn = 1'b0;
    repeat (19) @(posedge aclk);
    aresetn = 1'b1;
    $display("[%0t] aresetn deasserted", $time);

    // Inicializa flags
    saw_read = 1'b0;
    saw_trap = 1'b0;

    // Watchdog de atividade: até 20_000 ciclos de clock
    for (cycles = 0; cycles < 20000; cycles = cycles + 1) begin
      @(posedge aclk);

      if (cpu_trap && !saw_trap) begin
        $display("[%0t] CPU trap ASSERTED", $time);
        saw_trap = 1'b1;
      end

      if (m_arvalid && m_arready && !saw_read) begin
        $display("[%0t] AXI-AR handshake: ARADDR=0x%08x", $time, m_araddr);
      end

      if (m_rvalid && !saw_read) begin
        $display("[%0t] AXI-R valid   : RDATA = 0x%08x", $time, m_rdata);
        saw_read = 1'b1;
      end

      if (saw_read) begin
        // Observa alguns ciclos a mais e encerra
        repeat (50) @(posedge aclk);
        $display("[%0t] Encerrando apos primeira atividade de leitura.", $time);
        $stop;
      end
    end

    // Timeout sem tráfego
    $display("[%0t] finishing (timeout sem tráfego AXI nem trap)", $time);
    $stop;
  end

endmodule
