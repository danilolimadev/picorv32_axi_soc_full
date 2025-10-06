// ===== ADICIONADO: Comentários explicativos automáticos =====
// Este arquivo recebeu um bloco de comentários adicionais para
// auxiliar na simulação e entendimento. (picorv32.v foi mantido
// sem alterações por sua solicitação.)
// Você pode remover este bloco se preferir comentários mais curtos.

`timescale 1ns/1ps
// =============================================================================
// soc_top_picorv32_axi.v  (REFEITO)
// PicoRV32_AXI (master) -> AXI-Lite 1x2 -> [ RAM | Periféricos ]
// Mapa:
//   0x0000_0000 : RAM 64KB
//   0x4000_0000 : Periféricos (GPIO @ 0x4000_0000; demais +0x1000)
// =============================================================================

module soc_top_picorv32_axi (
  input  wire        aclk,
  input  wire        aresetn,

  input  wire [15:0] gpio_in,
  output wire [15:0] gpio_out,
  output wire [15:0] gpio_oe,

  output wire        cpu_trap
);

  // ===================== AXI MASTER (CPU) =====================
  wire [31:0] M_AWADDR;
  wire  [2:0] M_AWPROT;
  wire        M_AWVALID;
  wire        M_AWREADY;

  wire [31:0] M_WDATA;
  wire  [3:0] M_WSTRB;
  wire        M_WVALID;
  wire        M_WREADY;

  wire        M_BVALID;
  wire        M_BREADY;

  wire [31:0] M_ARADDR;
  wire  [2:0] M_ARPROT;
  wire        M_ARVALID;
  wire        M_ARREADY;

  wire [31:0] M_RDATA;
  wire        M_RVALID;
  wire        M_RREADY;

  // ===================== CPU =====================
  // Parâmetros compatíveis com seu picorv32_axi.v (sem LATCHED_MEM_RDATA)
  picorv32_axi #(
    .ENABLE_COUNTERS      (0),
    .ENABLE_COUNTERS64    (0),
    .ENABLE_REGS_16_31    (1),
    .ENABLE_REGS_DUALPORT (1),
    .TWO_STAGE_SHIFT      (1),
    .BARREL_SHIFTER       (0),
    .TWO_CYCLE_COMPARE    (0),
    .TWO_CYCLE_ALU        (0),
    .COMPRESSED_ISA       (0),
    .CATCH_MISALIGN       (1),
    .CATCH_ILLINSN        (1),
    .ENABLE_PCPI          (0),
    .ENABLE_MUL           (0), // use 1 se compilar FW com -march=rv32im
    .ENABLE_FAST_MUL      (0),
    .ENABLE_DIV           (0),
    .ENABLE_IRQ           (0),
    .ENABLE_IRQ_QREGS     (1),
    .ENABLE_IRQ_TIMER     (1),
    .ENABLE_TRACE         (0),
    .REGS_INIT_ZERO       (0),
    .MASKED_IRQ           (32'h0000_0000),
    .LATCHED_IRQ          (32'hFFFF_FFFF),
    .PROGADDR_RESET       (32'h0000_0000),
    .PROGADDR_IRQ         (32'h0000_0010),
    .STACKADDR            (32'h0000_FFFC)
  ) u_cpu (
    .clk   (aclk),
    .resetn(aresetn),
    .trap  (cpu_trap),

    // AXI4-Lite master — SEM *RESP no master
    .mem_axi_awvalid (M_AWVALID),
    .mem_axi_awready (M_AWREADY),
    .mem_axi_awaddr  (M_AWADDR),
    .mem_axi_awprot  (M_AWPROT),

    .mem_axi_wvalid  (M_WVALID),
    .mem_axi_wready  (M_WREADY),
    .mem_axi_wdata   (M_WDATA),
    .mem_axi_wstrb   (M_WSTRB),

    .mem_axi_bvalid  (M_BVALID),
    .mem_axi_bready  (M_BREADY),

    .mem_axi_arvalid (M_ARVALID),
    .mem_axi_arready (M_ARREADY),
    .mem_axi_araddr  (M_ARADDR),
    .mem_axi_arprot  (M_ARPROT),

    .mem_axi_rvalid  (M_RVALID),
    .mem_axi_rready  (M_RREADY),
    .mem_axi_rdata   (M_RDATA),

    // PCPI desabilitado
    .pcpi_valid(),
    .pcpi_insn (),
    .pcpi_rs1  (),
    .pcpi_rs2  (),
    .pcpi_wr   (1'b0),
    .pcpi_rd   (32'b0),
    .pcpi_wait (1'b0),
    .pcpi_ready(1'b0),

    // IRQ desabilitado
    .irq (32'b0),
    .eoi ()
  );

  // Defaults do master
  assign M_AWPROT = 3'b000;
  assign M_ARPROT = 3'b000;
  assign M_BREADY = 1'b1;
  assign M_RREADY = 1'b1;

  // ===================== 1 -> 2 DECODER =====================
  // S0: RAM (0x0000_0000/64KB)
  // S1: Periféricos (0x4000_0000/64KB)
  wire [31:0] S0_AWADDR, S0_WDATA, S0_ARADDR, S0_RDATA;
  wire  [2:0] S0_AWPROT, S0_ARPROT;
  wire  [3:0] S0_WSTRB;
  wire        S0_AWVALID, S0_AWREADY, S0_WVALID, S0_WREADY;
  wire        S0_BVALID;  wire S0_BREADY;
  wire        S0_ARVALID, S0_ARREADY;
  wire        S0_RVALID;  wire S0_RREADY;

  wire [31:0] S1_AWADDR, S1_WDATA, S1_ARADDR, S1_RDATA;
  wire  [2:0] S1_AWPROT, S1_ARPROT;
  wire  [3:0] S1_WSTRB;
  wire        S1_AWVALID, S1_AWREADY, S1_WVALID, S1_WREADY;
  wire        S1_BVALID;  wire S1_BREADY;
  wire        S1_ARVALID, S1_ARREADY;
  wire        S1_RVALID;  wire S1_RREADY;

  axi_lite_1to2_decoder #(
    .ADDR_MASK0 (32'hFFFF_0000), .ADDR_BASE0 (32'h0000_0000), // RAM
    .ADDR_MASK1 (32'hFFFF_0000), .ADDR_BASE1 (32'h4000_0000)  // PERIPH
  ) u_xbar_1x2 (
    .aclk(aclk), .aresetn(aresetn),

    // Master side (CPU)
    .M_AWADDR(M_AWADDR), .M_AWPROT(M_AWPROT), .M_AWVALID(M_AWVALID), .M_AWREADY(M_AWREADY),
    .M_WDATA (M_WDATA),  .M_WSTRB (M_WSTRB),  .M_WVALID (M_WVALID),  .M_WREADY (M_WREADY),
    .M_BVALID(M_BVALID), .M_BREADY(M_BREADY),
    .M_ARADDR(M_ARADDR), .M_ARPROT(M_ARPROT), .M_ARVALID(M_ARVALID), .M_ARREADY(M_ARREADY),
    .M_RDATA (M_RDATA),  .M_RVALID(M_RVALID), .M_RREADY (M_RREADY),

    // Slave 0: RAM
    .S0_AWADDR(S0_AWADDR), .S0_AWPROT(S0_AWPROT), .S0_AWVALID(S0_AWVALID), .S0_AWREADY(S0_AWREADY),
    .S0_WDATA (S0_WDATA),  .S0_WSTRB (S0_WSTRB),  .S0_WVALID (S0_WVALID),  .S0_WREADY (S0_WREADY),
    .S0_BVALID(S0_BVALID), .S0_BREADY(S0_BREADY),
    .S0_ARADDR(S0_ARADDR), .S0_ARPROT(S0_ARPROT), .S0_ARVALID(S0_ARVALID), .S0_ARREADY(S0_ARREADY),
    .S0_RDATA (S0_RDATA),  .S0_RVALID(S0_RVALID), .S0_RREADY (S0_RREADY),

    // Slave 1: Periféricos
    .S1_AWADDR(S1_AWADDR), .S1_AWPROT(S1_AWPROT), .S1_AWVALID(S1_AWVALID), .S1_AWREADY(S1_AWREADY),
    .S1_WDATA (S1_WDATA),  .S1_WSTRB (S1_WSTRB),  .S1_WVALID (S1_WVALID),  .S1_WREADY (S1_WREADY),
    .S1_BVALID(S1_BVALID), .S1_BREADY(S1_BREADY),
    .S1_ARADDR(S1_ARADDR), .S1_ARPROT(S1_ARPROT), .S1_ARVALID(S1_ARVALID), .S1_ARREADY(S1_ARREADY),
    .S1_RDATA (S1_RDATA),  .S1_RVALID(S1_RVALID), .S1_RREADY (S1_RREADY)
  );

  // ===================== RAM (64KB) =====================
  // Garanta dentro de mem_subsystem_axi:
  //   initial $readmemh("firmware.hex", mem);
  mem_subsystem_axi #(.BYTES(64*1024)) u_mem (
    .aclk(aclk), .aresetn(aresetn),
    .S_AWADDR(S0_AWADDR), .S_AWPROT(S0_AWPROT), .S_AWVALID(S0_AWVALID), .S_AWREADY(S0_AWREADY),
    .S_WDATA (S0_WDATA),  .S_WSTRB (S0_WSTRB),  .S_WVALID (S0_WVALID),  .S_WREADY (S0_WREADY),
    .S_BVALID(S0_BVALID), .S_BREADY(S0_BREADY),
    .S_ARADDR(S0_ARADDR), .S_ARPROT(S0_ARPROT), .S_ARVALID(S0_ARVALID), .S_ARREADY(S0_ARREADY),
    .S_RDATA (S0_RDATA),  .S_RVALID(S0_RVALID), .S_RREADY (S0_RREADY)
  );

  // ===================== PERIFÉRICOS =====================
  periph_subsystem_axi u_periph (
    .aclk(aclk), .aresetn(aresetn),
    .S_AWADDR(S1_AWADDR), .S_AWPROT(S1_AWPROT), .S_AWVALID(S1_AWVALID), .S_AWREADY(S1_AWREADY),
    .S_WDATA (S1_WDATA),  .S_WSTRB (S1_WSTRB),  .S_WVALID (S1_WVALID),  .S_WREADY (S1_WREADY),
    .S_BVALID(S1_BVALID), .S_BREADY(S1_BREADY),
    .S_ARADDR(S1_ARADDR), .S_ARPROT(S1_ARPROT), .S_ARVALID(S1_ARVALID), .S_ARREADY(S1_ARREADY),
    .S_RDATA (S1_RDATA),  .S_RVALID(S1_RVALID), .S_RREADY (S1_RREADY),

    .gpio_in(gpio_in), .gpio_out(gpio_out), .gpio_oe(gpio_oe)
  );

endmodule
