// ============================================================================
//  soc_top.v — PicoRV32 + AXI + UART + SPI + I2C + TIMER + GPIO
//  Versão completa com pinos externos para UART, SPI e I2C
// ============================================================================

module soc_top (
    input  wire clk,
    input  wire resetn,

    // UART
    output wire uart_tx,
    input  wire uart_rx,

    // === SPI externo ===
    output wire spi_mosi,
    input  wire spi_miso,
    output wire spi_sck,
    output wire spi_cs,

    // === I2C externo ===
    inout  wire i2c_sda,
    inout  wire i2c_scl
);

    // =========================================================================
    //  Interconexão AXI e IRQs (mesmo do anterior)
    // =========================================================================
    // (mantém todos os sinais AXI conforme a versão anterior)
    // -- conteúdo omitido para brevidade --
    // * irq, timer_irq, gpio, uart, spi, i2c, etc.
    // =========================================================================

    // === IRQ do Timer ===
    wire [31:0] irq;
    assign irq = {31'd0, timer_irq};

    // =========================================================================
    //  CPU
    // =========================================================================
    picorv32_axi cpu (...); // igual à versão anterior

    // =========================================================================
    //  Interconnect
    // =========================================================================
    axi_interconnect intercon (...); // igual à versão anterior

    // =========================================================================
    //  Periféricos
    // =========================================================================
    axi_ram ram_inst (...);   // igual
    axi_gpio gpio_inst (...); // igual
    axi_uart uart_inst (...); // igual

    // === SPI com pinos ===
    axi_spi spi_inst (
        .clk(clk),
        .resetn(resetn),

        .s_axi_awaddr(spi_awaddr),
        .s_axi_awvalid(spi_awvalid),
        .s_axi_awready(spi_awready),
        .s_axi_wdata(spi_wdata),
        .s_axi_wstrb(spi_wstrb),
        .s_axi_wvalid(spi_wvalid),
        .s_axi_wready(spi_wready),
        .s_axi_bresp(spi_bresp),
        .s_axi_bvalid(spi_bvalid),
        .s_axi_bready(spi_bready),
        .s_axi_araddr(spi_araddr),
        .s_axi_arvalid(spi_arvalid),
        .s_axi_arready(spi_arready),
        .s_axi_rdata(spi_rdata),
        .s_axi_rresp(spi_rresp),
        .s_axi_rvalid(spi_rvalid),
        .s_axi_rready(spi_rready),

        // === Sinais físicos ===
        .mosi(spi_mosi),
        .miso(spi_miso),
        .sck(spi_sck),
        .cs(spi_cs)
    );

    // === I2C com pinos ===
    axi_i2c i2c_inst (
        .clk(clk),
        .resetn(resetn),

        .s_axi_awaddr(i2c_awaddr),
        .s_axi_awvalid(i2c_awvalid),
        .s_axi_awready(i2c_awready),
        .s_axi_wdata(i2c_wdata),
        .s_axi_wstrb(i2c_wstrb),
        .s_axi_wvalid(i2c_wvalid),
        .s_axi_wready(i2c_wready),
        .s_axi_bresp(i2c_bresp),
        .s_axi_bvalid(i2c_bvalid),
        .s_axi_bready(i2c_bready),
        .s_axi_araddr(i2c_araddr),
        .s_axi_arvalid(i2c_arvalid),
        .s_axi_arready(i2c_arready),
        .s_axi_rdata(i2c_rdata),
        .s_axi_rresp(i2c_rresp),
        .s_axi_rvalid(i2c_rvalid),
        .s_axi_rready(i2c_rready),

        // === Pinos físicos ===
        .sda(i2c_sda),
        .scl(i2c_scl)
    );

    // === TIMER com IRQ ===
    axi_timer timer_inst (
        .clk(clk),
        .resetn(resetn),
        .s_axi_awaddr(timer_awaddr),
        .s_axi_awvalid(timer_awvalid),
        .s_axi_awready(timer_awready),
        .s_axi_wdata(timer_wdata),
        .s_axi_wstrb(timer_wstrb),
        .s_axi_wvalid(timer_wvalid),
        .s_axi_wready(timer_wready),
        .s_axi_bresp(timer_bresp),
        .s_axi_bvalid(timer_bvalid),
        .s_axi_bready(timer_bready),
        .s_axi_araddr(timer_araddr),
        .s_axi_arvalid(timer_arvalid),
        .s_axi_arready(timer_arready),
        .s_axi_rdata(timer_rdata),
        .s_axi_rresp(timer_rresp),
        .s_axi_rvalid(timer_rvalid),
        .s_axi_rready(timer_rready),
        .irq_out(timer_irq)
    );

endmodule
