// axi_spi.v - AXI-lite SPI stub (apenas regs para diretorio de teste)
module axi_spi (
    input wire clk,
    input wire resetn,
    input  wire [11:0] s_axi_awaddr,
    input  wire        s_axi_awvalid,
    output reg         s_axi_awready,
    input  wire [31:0] s_axi_wdata,
    input  wire [3:0]  s_axi_wstrb,
    input  wire        s_axi_wvalid,
    output reg         s_axi_wready,
    output reg [1:0]   s_axi_bresp,
    output reg         s_axi_bvalid,
    input  wire        s_axi_bready,
    input  wire [11:0] s_axi_araddr,
    input  wire        s_axi_arvalid,
    output reg         s_axi_arready,
    output reg [31:0]  s_axi_rdata,
    output reg [1:0]   s_axi_rresp,
    output reg         s_axi_rvalid,
    input  wire        s_axi_rready
);

    reg [31:0] ctrl;
    reg [31:0] txdata;
    reg [31:0] rxdata;
    // write
    always @(posedge clk) begin
        if (!resetn) begin
            s_axi_awready <= 0;
            s_axi_wready <= 0;
            s_axi_bvalid <= 0;
            ctrl <= 0;
            txdata <= 0;
            rxdata <= 0;
        end else begin
            s_axi_awready <= s_axi_awvalid && !s_axi_awready;
            s_axi_wready <= s_axi_wvalid && !s_axi_wready;
            if (s_axi_awvalid && s_axi_wvalid && s_axi_awready && s_axi_wready) begin
                s_axi_bvalid <= 1;
                s_axi_bresp <= 2'b00;
                case (s_axi_awaddr[3:0])
                    4'h0: ctrl <= s_axi_wdata;
                    4'h4: txdata <= s_axi_wdata;
                    default: ;
                endcase
                // loopback for rxdata as simple behavior
                rxdata <= txdata;
            end else if (s_axi_bvalid && s_axi_bready) begin
                s_axi_bvalid <= 0;
            end
        end
    end

    // read
    always @(posedge clk) begin
        if (!resetn) begin
            s_axi_arready <= 0;
            s_axi_rvalid <= 0;
        end else begin
            s_axi_arready <= s_axi_arvalid && !s_axi_arready;
            if (s_axi_arvalid && s_axi_arready) begin
                s_axi_rvalid <= 1;
                s_axi_rresp <= 2'b00;
                case (s_axi_araddr[3:0])
                    4'h0: s_axi_rdata <= ctrl;
                    4'h4: s_axi_rdata <= rxdata;
                    default: s_axi_rdata <= 32'hDEADBEEF;
                endcase
            end else if (s_axi_rvalid && s_axi_rready) begin
                s_axi_rvalid <= 0;
            end
        end
    end

endmodule
