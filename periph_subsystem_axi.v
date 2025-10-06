// ===== ADICIONADO: Comentários explicativos automáticos =====
// Este arquivo recebeu um bloco de comentários adicionais para
// auxiliar na simulação e entendimento. (picorv32.v foi mantido
// sem alterações por sua solicitação.)
// Você pode remover este bloco se preferir comentários mais curtos.

// ============================================================================
// periph_subsystem_axi.v  - AXI-Lite 1->4 + GPIO (full). UART/SPI/I2C = stubs.
// ============================================================================
module periph_subsystem_axi
(
    input  wire aclk, input wire aresetn,
    // AXI Slave (janela 0x4000_0000/64KB vinda do 1->2)
    input  wire [31:0] S_AWADDR, input wire [2:0] S_AWPROT, input wire S_AWVALID, output wire S_AWREADY,
    input  wire [31:0] S_WDATA,  input wire [3:0] S_WSTRB,  input wire S_WVALID,  output wire S_WREADY,
    output wire [1:0]  S_BRESP,  output wire S_BVALID,      input  wire S_BREADY,
    input  wire [31:0] S_ARADDR, input wire [2:0] S_ARPROT, input wire S_ARVALID, output wire S_ARREADY,
    output wire [31:0] S_RDATA,  output wire [1:0] S_RRESP,  output wire S_RVALID, input  wire S_RREADY,
    // GPIO físico
    input  wire [15:0] gpio_in,
    output wire [15:0] gpio_out,
    output wire [15:0] gpio_oe
);
    // Offsets locais (12 bits de página)
    localparam [31:0] BASE_GPIO = 32'h4000_0000;
    localparam [31:0] BASE_UART = 32'h4000_1000;
    localparam [31:0] BASE_SPI  = 32'h4000_2000;
    localparam [31:0] BASE_I2C  = 32'h4000_3000;
    localparam [31:0] MASK_4K   = 32'hFFFF_F000;

    // Canais para 4 slaves
    `define DECL_SX(n) \
    wire [31:0] S``n``_AWADDR, S``n``_WDATA, S``n``_ARADDR, S``n``_RDATA; \
    wire [2:0]  S``n``_AWPROT, S``n``_ARPROT; wire [3:0] S``n``_WSTRB; \
    wire S``n``_AWVALID, S``n``_AWREADY, S``n``_WVALID, S``n``_WREADY; \
    wire [1:0] S``n``_BRESP; wire S``n``_BVALID, S``n``_BREADY; \
    wire S``n``_ARVALID, S``n``_ARREADY; wire [1:0] S``n``_RRESP; wire S``n``_RVALID, S``n``_RREADY;

    `DECL_SX(0)  // GPIO
    `DECL_SX(1)  // UART
    `DECL_SX(2)  // SPI
    `DECL_SX(3)  // I2C
    `undef DECL_SX

    // Interconnect 1->4 (mesma lógica do 1->2, expandida)
    axi_lite_1toN_decoder #(
        .N(4),
        .MASK ( {4{MASK_4K}} ),
        .BASE ( {BASE_I2C, BASE_SPI, BASE_UART, BASE_GPIO} )
    ) u_xbar_1x4 (
        .aclk(aclk), .aresetn(aresetn),
        // M
        .M_AWADDR(S_AWADDR), .M_AWPROT(S_AWPROT), .M_AWVALID(S_AWVALID), .M_AWREADY(S_AWREADY),
        .M_WDATA (S_WDATA),  .M_WSTRB (S_WSTRB),  .M_WVALID (S_WVALID),  .M_WREADY (S_WREADY),
        .M_BRESP (S_BRESP),  .M_BVALID (S_BVALID),.M_BREADY (S_BREADY),
        .M_ARADDR(S_ARADDR), .M_ARPROT(S_ARPROT), .M_ARVALID(S_ARVALID), .M_ARREADY(S_ARREADY),
        .M_RDATA (S_RDATA),  .M_RRESP  (S_RRESP), .M_RVALID (S_RVALID),  .M_RREADY (S_RREADY),
        // S[0]
        .S0_AWADDR(S0_AWADDR), .S0_AWPROT(S0_AWPROT), .S0_AWVALID(S0_AWVALID), .S0_AWREADY(S0_AWREADY),
        .S0_WDATA (S0_WDATA),  .S0_WSTRB (S0_WSTRB),  .S0_WVALID (S0_WVALID),  .S0_WREADY (S0_WREADY),
        .S0_BRESP (S0_BRESP),  .S0_BVALID (S0_BVALID),.S0_BREADY (S0_BREADY),
        .S0_ARADDR(S0_ARADDR), .S0_ARPROT(S0_ARPROT), .S0_ARVALID(S0_ARVALID), .S0_ARREADY(S0_ARREADY),
        .S0_RDATA (S0_RDATA),  .S0_RRESP  (S0_RRESP), .S0_RVALID (S0_RVALID),  .S0_RREADY (S0_RREADY),
        // S[1]
        .S1_AWADDR(S1_AWADDR), .S1_AWPROT(S1_AWPROT), .S1_AWVALID(S1_AWVALID), .S1_AWREADY(S1_AWREADY),
        .S1_WDATA (S1_WDATA),  .S1_WSTRB (S1_WSTRB),  .S1_WVALID (S1_WVALID),  .S1_WREADY (S1_WREADY),
        .S1_BRESP (S1_BRESP),  .S1_BVALID (S1_BVALID),.S1_BREADY (S1_BREADY),
        .S1_ARADDR(S1_ARADDR), .S1_ARPROT(S1_ARPROT), .S1_ARVALID(S1_ARVALID), .S1_ARREADY(S1_ARREADY),
        .S1_RDATA (S1_RDATA),  .S1_RRESP  (S1_RRESP), .S1_RVALID (S1_RVALID),  .S1_RREADY (S1_RREADY),
        // S[2]
        .S2_AWADDR(S2_AWADDR), .S2_AWPROT(S2_AWPROT), .S2_AWVALID(S2_AWVALID), .S2_AWREADY(S2_AWREADY),
        .S2_WDATA (S2_WDATA),  .S2_WSTRB (S2_WSTRB),  .S2_WVALID (S2_WVALID),  .S2_WREADY (S2_WREADY),
        .S2_BRESP (S2_BRESP),  .S2_BVALID (S2_BVALID),.S2_BREADY (S2_BREADY),
        .S2_ARADDR(S2_ARADDR), .S2_ARPROT(S2_ARPROT), .S2_ARVALID(S2_ARVALID), .S2_ARREADY(S2_ARREADY),
        .S2_RDATA (S2_RDATA),  .S2_RRESP  (S2_RRESP), .S2_RVALID (S2_RVALID),  .S2_RREADY (S2_RREADY),
        // S[3]
        .S3_AWADDR(S3_AWADDR), .S3_AWPROT(S3_AWPROT), .S3_AWVALID(S3_AWVALID), .S3_AWREADY(S3_AWREADY),
        .S3_WDATA (S3_WDATA),  .S3_WSTRB (S3_WSTRB),  .S3_WVALID (S3_WVALID),  .S3_WREADY (S3_WREADY),
        .S3_BRESP (S3_BRESP),  .S3_BVALID (S3_BVALID),.S3_BREADY (S3_BREADY),
        .S3_ARADDR(S3_ARADDR), .S3_ARPROT(S3_ARPROT), .S3_ARVALID(S3_ARVALID), .S3_ARREADY(S3_ARREADY),
        .S3_RDATA (S3_RDATA),  .S3_RRESP  (S3_RRESP), .S3_RVALID (S3_RVALID),  .S3_RREADY (S3_RREADY)
    );

    // ---------------------- GPIO (completo) ----------------------
    gpio_axi #(.WIDTH(16)) u_gpio (
        .aclk(aclk), .aresetn(aresetn),
        .S_AWADDR (S0_AWADDR), .S_AWPROT (S0_AWPROT), .S_AWVALID(S0_AWVALID), .S_AWREADY(S0_AWREADY),
        .S_WDATA  (S0_WDATA),  .S_WSTRB  (S0_WSTRB),  .S_WVALID (S0_WVALID),  .S_WREADY (S0_WREADY),
        .S_BRESP  (S0_BRESP),  .S_BVALID (S0_BVALID), .S_BREADY (S0_BREADY),
        .S_ARADDR (S0_ARADDR), .S_ARPROT (S0_ARPROT), .S_ARVALID(S0_ARVALID), .S_ARREADY(S0_ARREADY),
        .S_RDATA  (S0_RDATA),  .S_RRESP  (S0_RRESP),  .S_RVALID (S0_RVALID),  .S_RREADY (S0_RREADY),
        .gpio_in(gpio_in), .gpio_out(gpio_out), .gpio_oe(gpio_oe)
    );

    // ---------------------- UART/SPI/I2C (stubs endereçáveis) ----------------
    axi_lite_stub u_uart (.aclk(aclk), .aresetn(aresetn),
        .S_AWADDR(S1_AWADDR),.S_AWPROT(S1_AWPROT),.S_AWVALID(S1_AWVALID),.S_AWREADY(S1_AWREADY),
        .S_WDATA(S1_WDATA),.S_WSTRB(S1_WSTRB),.S_WVALID(S1_WVALID),.S_WREADY(S1_WREADY),
        .S_BRESP(S1_BRESP),.S_BVALID(S1_BVALID),.S_BREADY(S1_BREADY),
        .S_ARADDR(S1_ARADDR),.S_ARPROT(S1_ARPROT),.S_ARVALID(S1_ARVALID),.S_ARREADY(S1_ARREADY),
        .S_RDATA(S1_RDATA),.S_RRESP(S1_RRESP),.S_RVALID(S1_RVALID),.S_RREADY(S1_RREADY)
    );
    axi_lite_stub u_spi  (.aclk(aclk), .aresetn(aresetn),
        .S_AWADDR(S2_AWADDR),.S_AWPROT(S2_AWPROT),.S_AWVALID(S2_AWVALID),.S_AWREADY(S2_AWREADY),
        .S_WDATA(S2_WDATA),.S_WSTRB(S2_WSTRB),.S_WVALID(S2_WVALID),.S_WREADY(S2_WREADY),
        .S_BRESP(S2_BRESP),.S_BVALID(S2_BVALID),.S_BREADY(S2_BREADY),
        .S_ARADDR(S2_ARADDR),.S_ARPROT(S2_ARPROT),.S_ARVALID(S2_ARVALID),.S_ARREADY(S2_ARREADY),
        .S_RDATA(S2_RDATA),.S_RRESP(S2_RRESP),.S_RVALID(S2_RVALID),.S_RREADY(S2_RREADY)
    );
    axi_lite_stub u_i2c  (.aclk(aclk), .aresetn(aresetn),
        .S_AWADDR(S3_AWADDR),.S_AWPROT(S3_AWPROT),.S_AWVALID(S3_AWVALID),.S_AWREADY(S3_AWREADY),
        .S_WDATA(S3_WDATA),.S_WSTRB(S3_WSTRB),.S_WVALID(S3_WVALID),.S_WREADY(S3_WREADY),
        .S_BRESP(S3_BRESP),.S_BVALID(S3_BVALID),.S_BREADY(S3_BREADY),
        .S_ARADDR(S3_ARADDR),.S_ARPROT(S3_ARPROT),.S_ARVALID(S3_ARVALID),.S_ARREADY(S3_ARREADY),
        .S_RDATA(S3_RDATA),.S_RRESP(S3_RRESP),.S_RVALID(S3_RVALID),.S_RREADY(S3_RREADY)
    );
endmodule
