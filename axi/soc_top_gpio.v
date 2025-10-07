module soc_top (
    input  wire clk,
    input  wire resetn
);

    // --------------------------
    // AXI Master signals (CPU)
    // --------------------------
    wire [31:0]  m_axi_awaddr;
    wire [7:0]   m_axi_awlen;
    wire [2:0]   m_axi_awsize;
    wire [1:0]   m_axi_awburst;
    wire         m_axi_awvalid;
    wire         m_axi_awready;

    wire [31:0]  m_axi_wdata;
    wire [3:0]   m_axi_wstrb;
    wire         m_axi_wlast;
    wire         m_axi_wvalid;
    wire         m_axi_wready;

    wire [1:0]   m_axi_bresp;
    wire         m_axi_bvalid;
    wire         m_axi_bready;

    wire [31:0]  m_axi_araddr;
    wire [7:0]   m_axi_arlen;
    wire [2:0]   m_axi_arsize;
    wire [1:0]   m_axi_arburst;
    wire         m_axi_arvalid;
    wire         m_axi_arready;

    wire [31:0]  m_axi_rdata;
    wire [1:0]   m_axi_rresp;
    wire         m_axi_rlast;
    wire         m_axi_rvalid;
    wire         m_axi_rready;

    // --------------------------
    // CPU
    // --------------------------
    picorv32_axi cpu (
        .clk        (clk),
        .resetn     (resetn),

        .m_axi_awaddr  (m_axi_awaddr),
        .m_axi_awlen   (m_axi_awlen),
        .m_axi_awsize  (m_axi_awsize),
        .m_axi_awburst (m_axi_awburst),
        .m_axi_awvalid (m_axi_awvalid),
        .m_axi_awready (m_axi_awready),

        .m_axi_wdata   (m_axi_wdata),
        .m_axi_wstrb   (m_axi_wstrb),
        .m_axi_wlast   (m_axi_wlast),
        .m_axi_wvalid  (m_axi_wvalid),
        .m_axi_wready  (m_axi_wready),

        .m_axi_bresp   (m_axi_bresp),
        .m_axi_bvalid  (m_axi_bvalid),
        .m_axi_bready  (m_axi_bready),

        .m_axi_araddr  (m_axi_araddr),
        .m_axi_arlen   (m_axi_arlen),
        .m_axi_arsize  (m_axi_arsize),
        .m_axi_arburst (m_axi_arburst),
        .m_axi_arvalid (m_axi_arvalid),
        .m_axi_arready (m_axi_arready),

        .m_axi_rdata   (m_axi_rdata),
        .m_axi_rresp   (m_axi_rresp),
        .m_axi_rlast   (m_axi_rlast),
        .m_axi_rvalid  (m_axi_rvalid),
        .m_axi_rready  (m_axi_rready)
    );

    // --------------------------
    // RAM (AXI Slave)
    // --------------------------
    axi_ram #(
        .ADDR_WIDTH(16),   // 64KB
        .DATA_WIDTH(32)
    ) ram (
        .clk(clk),
        .resetn(resetn),

        .s_axi_awaddr (m_axi_awaddr),
        .s_axi_awvalid(m_axi_awvalid),
        .s_axi_awready(m_axi_awready),

        .s_axi_wdata  (m_axi_wdata),
        .s_axi_wstrb  (m_axi_wstrb),
        .s_axi_wvalid (m_axi_wvalid),
        .s_axi_wready (m_axi_wready),

        .s_axi_bresp  (m_axi_bresp),
        .s_axi_bvalid (m_axi_bvalid),
        .s_axi_bready (m_axi_bready),

        .s_axi_araddr (m_axi_araddr),
        .s_axi_arvalid(m_axi_arvalid),
        .s_axi_arready(m_axi_arready),

        .s_axi_rdata  (m_axi_rdata),
        .s_axi_rresp  (m_axi_rresp),
        .s_axi_rvalid (m_axi_rvalid),
        .s_axi_rready (m_axi_rready)
    );

    // Decodificação do endereço
    wire sel_ram  = (m_axi_awaddr[31:16] == 16'h0000);
    wire sel_gpio = (m_axi_awaddr[31:16] == 16'h4000);

    // Instância do GPIO
    axi_gpio u_gpio (
        .clk(clk), .resetn(resetn),
        .s_axi_awaddr(m_axi_awaddr[11:0]),
        .s_axi_awvalid(sel_gpio ? m_axi_awvalid : 1'b0),
        .s_axi_awready(),
        .s_axi_wdata(m_axi_wdata),
        .s_axi_wstrb(m_axi_wstrb),
        .s_axi_wvalid(sel_gpio ? m_axi_wvalid : 1'b0),
        .s_axi_wready(),
        .s_axi_bresp(),
        .s_axi_bvalid(),
        .s_axi_bready(m_axi_bready),
        .s_axi_araddr(m_axi_araddr[11:0]),
        .s_axi_arvalid(sel_gpio ? m_axi_arvalid : 1'b0),
        .s_axi_arready(),
        .s_axi_rdata(),
        .s_axi_rresp(),
        .s_axi_rvalid(),
        .s_axi_rready(m_axi_rready),
        .gpio_out(gpio_out)
    );


endmodule
