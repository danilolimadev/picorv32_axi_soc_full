// ===== ADICIONADO: Comentários explicativos automáticos =====
// Este arquivo recebeu um bloco de comentários adicionais para
// auxiliar na simulação e entendimento. (picorv32.v foi mantido
// sem alterações por sua solicitação.)
// Você pode remover este bloco se preferir comentários mais curtos.

`timescale 1ns/1ps

// ============================================================================
// tb_soc_axi_bfm.v  (Verilog-2001)
// BFM de AXI4-Lite para validar: 1->2 decoder + RAM + 1->4 peripherals (GPIO real)
// - Logs no transcript
// - Watchdog (2 ms)
// - Timeouts por handshake (evita loops silenciosos)
// ============================================================================

module tb_soc_axi_bfm;

  // ---------------- Clock / Reset ----------------
  reg aclk = 1'b0;
  always #5 aclk = ~aclk; // 100 MHz

  reg aresetn = 1'b0;

  // ---------------- GPIO físicos (loopback) ----------------
  reg  [15:0] gpio_in  = 16'hA5A5;
  wire [15:0] gpio_out;
  wire [15:0] gpio_oe;

  // ---------------- Master (BFM) ----------------
  reg  [31:0] M_AWADDR, M_WDATA, M_ARADDR;
  reg   [2:0] M_AWPROT, M_ARPROT;
  reg   [3:0] M_WSTRB;
  reg         M_AWVALID, M_WVALID, M_BREADY, M_ARVALID, M_RREADY;
  wire        M_AWREADY, M_WREADY, M_BVALID, M_ARREADY, M_RVALID;
  wire [31:0] M_RDATA;
  wire  [1:0] M_BRESP, M_RRESP;

  // ---------------- Slave 0 (Memory) ----------------
  wire [31:0] S0_AWADDR, S0_WDATA, S0_ARADDR, S0_RDATA;
  wire  [2:0] S0_AWPROT, S0_ARPROT;
  wire  [3:0] S0_WSTRB;
  wire        S0_AWVALID, S0_AWREADY, S0_WVALID, S0_WREADY;
  wire  [1:0] S0_BRESP;  wire S0_BVALID, S0_BREADY;
  wire        S0_ARVALID, S0_ARREADY;
  wire  [1:0] S0_RRESP;  wire S0_RVALID, S0_RREADY;

  // ---------------- Slave 1 (Peripherals) ----------------
  wire [31:0] S1_AWADDR, S1_WDATA, S1_ARADDR, S1_RDATA;
  wire  [2:0] S1_AWPROT, S1_ARPROT;
  wire  [3:0] S1_WSTRB;
  wire        S1_AWVALID, S1_AWREADY, S1_WVALID, S1_WREADY;
  wire  [1:0] S1_BRESP;  wire S1_BVALID, S1_BREADY;
  wire        S1_ARVALID, S1_ARREADY;
  wire  [1:0] S1_RRESP;  wire S1_RVALID, S1_RREADY;

  // ---------------- Vars de leitura ----------------
  reg [31:0] r0, r1, rin;

  // ---------------- Decoder 1->2 (MEM/PERIPH) ----------------
  axi_lite_1to2_decoder #(
    .ADDR_MASK0 (32'hFFFF_0000), .ADDR_BASE0 (32'h0000_0000), // MEM 64KB
    .ADDR_MASK1 (32'hFFFF_0000), .ADDR_BASE1 (32'h4000_0000)  // PERIPH 64KB
  ) u_xbar_1x2 (
    .aclk(aclk), .aresetn(aresetn),

    .M_AWADDR(M_AWADDR), .M_AWPROT(M_AWPROT), .M_AWVALID(M_AWVALID), .M_AWREADY(M_AWREADY),
    .M_WDATA (M_WDATA),  .M_WSTRB (M_WSTRB),  .M_WVALID (M_WVALID),  .M_WREADY (M_WREADY),
    .M_BRESP (M_BRESP),  .M_BVALID (M_BVALID),.M_BREADY (M_BREADY),
    .M_ARADDR(M_ARADDR), .M_ARPROT(M_ARPROT), .M_ARVALID(M_ARVALID), .M_ARREADY(M_ARREADY),
    .M_RDATA (M_RDATA),  .M_RRESP  (M_RRESP), .M_RVALID (M_RVALID),  .M_RREADY (M_RREADY),

    .S0_AWADDR(S0_AWADDR), .S0_AWPROT(S0_AWPROT), .S0_AWVALID(S0_AWVALID), .S0_AWREADY(S0_AWREADY),
    .S0_WDATA (S0_WDATA),  .S0_WSTRB (S0_WSTRB),  .S0_WVALID (S0_WVALID),  .S0_WREADY (S0_WREADY),
    .S0_BRESP (S0_BRESP),  .S0_BVALID (S0_BVALID),.S0_BREADY (S0_BREADY),
    .S0_ARADDR(S0_ARADDR), .S0_ARPROT(S0_ARPROT), .S0_ARVALID(S0_ARVALID), .S0_ARREADY(S0_ARREADY),
    .S0_RDATA (S0_RDATA),  .S0_RRESP  (S0_RRESP), .S0_RVALID (S0_RVALID),  .S0_RREADY (S0_RREADY),

    .S1_AWADDR(S1_AWADDR), .S1_AWPROT(S1_AWPROT), .S1_AWVALID(S1_AWVALID), .S1_AWREADY(S1_AWREADY),
    .S1_WDATA (S1_WDATA),  .S1_WSTRB (S1_WSTRB),  .S1_WVALID (S1_WVALID),  .S1_WREADY (S1_WREADY),
    .S1_BRESP (S1_BRESP),  .S1_BVALID (S1_BVALID),.S1_BREADY (S1_BREADY),
    .S1_ARADDR(S1_ARADDR), .S1_ARPROT(S1_ARPROT), .S1_ARVALID(S1_ARVALID), .S1_ARREADY(S1_ARREADY),
    .S1_RDATA (S1_RDATA),  .S1_RRESP  (S1_RRESP), .S1_RVALID (S1_RVALID),  .S1_RREADY (S1_RREADY)
  );

  // ---------------- RAM 64KB ----------------
  mem_subsystem_axi #(.BYTES(64*1024)) u_mem (
    .aclk(aclk), .aresetn(aresetn),
    .S_AWADDR(S0_AWADDR), .S_AWPROT(S0_AWPROT), .S_AWVALID(S0_AWVALID), .S_AWREADY(S0_AWREADY),
    .S_WDATA (S0_WDATA),  .S_WSTRB (S0_WSTRB),  .S_WVALID (S0_WVALID),  .S_WREADY (S0_WREADY),
    .S_BRESP (S0_BRESP),  .S_BVALID (S0_BVALID), .S_BREADY (S0_BREADY),
    .S_ARADDR(S0_ARADDR), .S_ARPROT(S0_ARPROT), .S_ARVALID(S0_ARVALID), .S_ARREADY(S0_ARREADY),
    .S_RDATA (S0_RDATA),  .S_RRESP (S0_RRESP),  .S_RVALID (S0_RVALID),  .S_RREADY (S0_RREADY)
  );

  // ---------------- Peripherals (1->4 + GPIO + stubs) ----------------
  periph_subsystem_axi u_periph (
    .aclk(aclk), .aresetn(aresetn),
    .S_AWADDR(S1_AWADDR), .S_AWPROT(S1_AWPROT), .S_AWVALID(S1_AWVALID), .S_AWREADY(S1_AWREADY),
    .S_WDATA (S1_WDATA),  .S_WSTRB (S1_WSTRB),  .S_WVALID (S1_WVALID),  .S_WREADY (S1_WREADY),
    .S_BRESP (S1_BRESP),  .S_BVALID (S1_BVALID), .S_BREADY (S1_BREADY),
    .S_ARADDR(S1_ARADDR), .S_ARPROT(S1_ARPROT), .S_ARVALID(S1_ARVALID), .S_ARREADY(S1_ARREADY),
    .S_RDATA (S1_RDATA),  .S_RRESP (S1_RRESP),  .S_RVALID (S1_RVALID),  .S_RREADY (S1_RREADY),
    .gpio_in(gpio_in), .gpio_out(gpio_out), .gpio_oe(gpio_oe)
  );

  // ---------------- Diagnóstico local de seleção ----------------
  // Útil para ver se o endereço do BFM está caindo em alguma janela
  wire sel_mem_aw = ((M_AWADDR & 32'hFFFF_0000) == 32'h0000_0000);
  wire sel_prf_aw = ((M_AWADDR & 32'hFFFF_0000) == 32'h4000_0000);
  wire sel_mem_ar = ((M_ARADDR & 32'hFFFF_0000) == 32'h0000_0000);
  wire sel_prf_ar = ((M_ARADDR & 32'hFFFF_0000) == 32'h4000_0000);

// ================== TAREFAS AXI-Lite (CORRIGIDAS) ==================
  task axi_write(input [31:0] addr, input [31:0] data);
    integer t_aw, t_w, t_b;
    begin
      $display("[%0t] AXI-WR  addr=0x%08h data=0x%08h (sel_mem=%0d sel_prf=%0d)", $time, addr, data,
               ((addr & 32'hFFFF_0000)==32'h0000_0000), ((addr & 32'hFFFF_0000)==32'h4000_0000));

      // Drive VALIDs
      M_AWADDR  <= addr;  M_AWPROT <= 3'b000; M_AWVALID <= 1'b1;
      M_WDATA   <= data;  M_WSTRB  <= 4'hF;   M_WVALID  <= 1'b1;
      M_BREADY  <= 1'b1;

      // Espera os handshakes NO FLANCO (VALID && READY)
      t_aw = 0; t_w = 0;
      fork
        begin
          while (!(M_AWVALID && M_AWREADY)) begin
            @(posedge aclk); t_aw = t_aw + 1;
            if (t_aw>10000) begin
              $error("[%0t] TIMEOUT: AW handshake não ocorreu (addr=0x%08h)", $time, addr);
              $fatal;
            end
          end
        end
        begin
          while (!(M_WVALID && M_WREADY)) begin
            @(posedge aclk); t_w = t_w + 1;
            if (t_w>10000) begin
              $error("[%0t] TIMEOUT: W handshake não ocorreu (addr=0x%08h)", $time, addr);
              $fatal;
            end
          end
        end
      join

      // Desasserta VALIDs após os respectivos handshakes
      M_AWVALID <= 1'b0;
      M_WVALID  <= 1'b0;

      // Espera a resposta de write (BVALID && BREADY) NO FLANCO
      t_b = 0;
      while (!(M_BVALID && M_BREADY)) begin
        @(posedge aclk); t_b = t_b + 1;
        if (t_b>10000) begin
          $error("[%0t] TIMEOUT: BVALID não veio (addr=0x%08h)", $time, addr);
          $fatal;
        end
      end
      M_BREADY <= 1'b0; // resposta consumida
    end
  endtask

  task axi_read(input [31:0] addr, output [31:0] data);
    integer t_ar, t_r;
    begin
      $display("[%0t] AXI-RD  addr=0x%08h (sel_mem=%0d sel_prf=%0d)", $time, addr,
               ((addr & 32'hFFFF_0000)==32'h0000_0000), ((addr & 32'hFFFF_0000)==32'h4000_0000));

      // Drive VALID
      M_ARADDR  <= addr; M_ARPROT <= 3'b000; M_ARVALID <= 1'b1;
      M_RREADY  <= 1'b1;

      // Handshake AR NO FLANCO
      t_ar = 0;
      while (!(M_ARVALID && M_ARREADY)) begin
        @(posedge aclk); t_ar = t_ar + 1;
        if (t_ar>10000) begin
          $error("[%0t] TIMEOUT: AR handshake não ocorreu (addr=0x%08h)", $time, addr);
          $fatal;
        end
      end
      M_ARVALID <= 1'b0;

      // Handshake R NO FLANCO
      t_r = 0;
      while (!(M_RVALID && M_RREADY)) begin
        @(posedge aclk); t_r = t_r + 1;
        if (t_r>10000) begin
          $error("[%0t] TIMEOUT: RVALID não veio (addr=0x%08h)", $time, addr);
          $fatal;
        end
      end
      data = M_RDATA;
      M_RREADY <= 1'b0;
    end
  endtask

  // ---------------- Sequência de teste ----------------
  initial begin
    $timeformat(-9,3," ns",10);
    $display("[%0t] TB start (sanity)", $time);

    // init master
    M_AWADDR=0; M_WDATA=0; M_ARADDR=0;
    M_AWPROT=0; M_ARPROT=0; M_WSTRB=0;
    M_AWVALID=0; M_WVALID=0; M_BREADY=0; M_ARVALID=0; M_RREADY=0;

    // reset hold e release
    repeat(10) @(posedge aclk);
    aresetn <= 1'b1;
    $display("[%0t] aresetn deasserted (sanity)", $time);

    // 1) RAM write/read
    axi_write(32'h0000_0000, 32'h1234_5678);
    axi_write(32'h0000_0004, 32'hCAFEBABE);
    axi_read (32'h0000_0000, r0);
    axi_read (32'h0000_0004, r1);
    $display("[%0t] RAM r0=0x%08h r1=0x%08h", $time, r0, r1);
    if (r0!==32'h1234_5678 || r1!==32'hCAFEBABE) begin
      $error("[%0t] RAM mismatch!", $time);
      $fatal;
    end

    // 2) GPIO DIR/OUT e leitura de IN
    axi_write(32'h4000_0000, 32'h0000_FFFF); // DIR
    axi_write(32'h4000_0004, 32'h0000_0003); // OUT
    axi_read (32'h4000_0008, rin);           // IN
    $display("[%0t] GPIO.IN = 0x%08h (esperado 0x0000A5A5)", $time, rin);

    // 3) Alterar gpio_in e reler
    gpio_in <= 16'h55AA;
    repeat(2) @(posedge aclk);
    axi_read (32'h4000_0008, rin);
    $display("[%0t] GPIO.IN (after change) = 0x%08h", $time, rin);
    if (rin[15:0]!==16'h55AA) begin
      $error("[%0t] GPIO.IN mismatch", $time);
      $fatal;
    end

    $display("[%0t] BFM AXI-Lite OK.", $time);
    #100;
    $finish;
  end

  // ---------------- Watchdog global ----------------
  initial begin
    #2_000_000; // 2 ms @ 1ns
    $display("[%0t] WATCHDOG: timeout geral.", $time);
    $fatal;
  end

endmodule
