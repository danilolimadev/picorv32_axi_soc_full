// ===== ADICIONADO: Comentários explicativos automáticos =====
// Este arquivo recebeu um bloco de comentários adicionais para
// auxiliar na simulação e entendimento. (picorv32.v foi mantido
// sem alterações por sua solicitação.)
// Você pode remover este bloco se preferir comentários mais curtos.

// ============================================================================
// axi_lite_1to2_decoder.v  (AXI4-Lite 1 -> 2)
// Correção: seleção do canal B e R LATCHED no handshake de AW/AR.
// Compatível Verilog-2001.
// ============================================================================

module axi_lite_1to2_decoder #(
    parameter [31:0] ADDR_MASK0 = 32'hFFFF_0000,
    parameter [31:0] ADDR_BASE0 = 32'h0000_0000,
    parameter [31:0] ADDR_MASK1 = 32'hFFFF_0000,
    parameter [31:0] ADDR_BASE1 = 32'h4000_0000
)(
    input  wire aclk,
    input  wire aresetn,
    // Master
    input  wire [31:0] M_AWADDR, input wire [2:0] M_AWPROT, input wire M_AWVALID, output wire M_AWREADY,
    input  wire [31:0] M_WDATA,  input wire [3:0] M_WSTRB,  input wire M_WVALID,  output wire M_WREADY,
    output reg  [1:0]  M_BRESP,  output reg  M_BVALID,      input  wire M_BREADY,

    input  wire [31:0] M_ARADDR, input wire [2:0] M_ARPROT, input wire M_ARVALID, output wire M_ARREADY,
    output reg  [31:0] M_RDATA,  output reg  [1:0] M_RRESP, output reg  M_RVALID,  input  wire M_RREADY,
    // Slave 0
    output wire [31:0] S0_AWADDR, output wire [2:0] S0_AWPROT, output wire S0_AWVALID, input wire S0_AWREADY,
    output wire [31:0] S0_WDATA,  output wire [3:0] S0_WSTRB,  output wire S0_WVALID,  input wire S0_WREADY,
    input  wire [1:0]  S0_BRESP,  input  wire S0_BVALID,      output wire S0_BREADY,
    output wire [31:0] S0_ARADDR, output wire [2:0] S0_ARPROT, output wire S0_ARVALID, input wire S0_ARREADY,
    input  wire [31:0] S0_RDATA,  input  wire [1:0] S0_RRESP,  input  wire S0_RVALID,  output wire S0_RREADY,
    // Slave 1
    output wire [31:0] S1_AWADDR, output wire [2:0] S1_AWPROT, output wire S1_AWVALID, input wire S1_AWREADY,
    output wire [31:0] S1_WDATA,  output wire [3:0] S1_WSTRB,  output wire S1_WVALID,  input wire S1_WREADY,
    input  wire [1:0]  S1_BRESP,  input  wire S1_BVALID,      output wire S1_BREADY,
    output wire [31:0] S1_ARADDR, output wire [2:0] S1_ARPROT, output wire S1_ARVALID, input  wire S1_ARREADY,
    input  wire [31:0] S1_RDATA,  input  wire [1:0] S1_RRESP,  input  wire S1_RVALID,  output wire S1_RREADY
);
    // ---------------- Seleção combinacional por endereço ----------------
    wire sel_aw0_c = ((M_AWADDR & ADDR_MASK0) == ADDR_BASE0);
    wire sel_aw1_c = ((M_AWADDR & ADDR_MASK1) == ADDR_BASE1);
    wire sel_ar0_c = ((M_ARADDR & ADDR_MASK0) == ADDR_BASE0);
    wire sel_ar1_c = ((M_ARADDR & ADDR_MASK1) == ADDR_BASE1);

    // ---------------- Latches de destino (um outstanding por canal) ------
    // aw_sel: 0 => S0, 1 => S1; aw_busy indica resposta pendente
    reg aw_sel, aw_busy;
    always @(posedge aclk) begin
        if (!aresetn) begin
            aw_sel  <= 1'b0;
            aw_busy <= 1'b0;
        end else begin
            // Captura no handshake de AW
            if (!aw_busy && M_AWVALID && M_AWREADY) begin
                aw_sel  <= sel_aw1_c; // 0=S0, 1=S1
                aw_busy <= 1'b1;
            end
            // Libera quando B for aceito
            if (M_BVALID && M_BREADY) begin
                aw_busy <= 1'b0;
            end
        end
    end

    // ar_sel/ ar_busy para o canal de leitura
    reg ar_sel, ar_busy;
    always @(posedge aclk) begin
        if (!aresetn) begin
            ar_sel  <= 1'b0;
            ar_busy <= 1'b0;
        end else begin
            if (!ar_busy && M_ARVALID && M_ARREADY) begin
                ar_sel  <= sel_ar1_c;
                ar_busy <= 1'b1;
            end
            if (M_RVALID && M_RREADY) begin
                ar_busy <= 1'b0;
            end
        end
    end

    // ---------------- WRITE ADDRESS/DATA ----------------
    assign S0_AWADDR  = M_AWADDR;  assign S0_AWPROT = M_AWPROT; assign S0_AWVALID = M_AWVALID & sel_aw0_c;
    assign S1_AWADDR  = M_AWADDR;  assign S1_AWPROT = M_AWPROT; assign S1_AWVALID = M_AWVALID & sel_aw1_c;
    assign M_AWREADY  = (sel_aw0_c ? S0_AWREADY : 1'b0) | (sel_aw1_c ? S1_AWREADY : 1'b0);

    assign S0_WDATA   = M_WDATA;   assign S0_WSTRB  = M_WSTRB;  assign S0_WVALID  = M_WVALID & sel_aw0_c;
    assign S1_WDATA   = M_WDATA;   assign S1_WSTRB  = M_WSTRB;  assign S1_WVALID  = M_WVALID & sel_aw1_c;
    assign M_WREADY   = (sel_aw0_c ? S0_WREADY : 1'b0) | (sel_aw1_c ? S1_WREADY : 1'b0);

    assign S0_BREADY  = M_BREADY;
    assign S1_BREADY  = M_BREADY;

    // ---------------- WRITE RESPONSE (mux por aw_sel latched) ------------
    always @* begin
        if (!aw_busy) begin
            M_BVALID = 1'b0;
            M_BRESP  = 2'b00;
        end else begin
            if (aw_sel == 1'b0) begin
                M_BVALID = S0_BVALID;
                M_BRESP  = S0_BRESP;
            end else begin
                M_BVALID = S1_BVALID;
                M_BRESP  = S1_BRESP;
            end
        end
    end

    // ---------------- READ ADDRESS ----------------
    assign S0_ARADDR  = M_ARADDR;  assign S0_ARPROT = M_ARPROT; assign S0_ARVALID = M_ARVALID & sel_ar0_c;
    assign S1_ARADDR  = M_ARADDR;  assign S1_ARPROT = M_ARPROT; assign S1_ARVALID = M_ARVALID & sel_ar1_c;
    assign M_ARREADY  = (sel_ar0_c ? S0_ARREADY : 1'b0) | (sel_ar1_c ? S1_ARREADY : 1'b0);

    assign S0_RREADY  = M_RREADY;
    assign S1_RREADY  = M_RREADY;

    // ---------------- READ DATA (mux por ar_sel latched) -----------------
    always @* begin
        if (!ar_busy) begin
            M_RVALID = 1'b0;
            M_RRESP  = 2'b00;
            M_RDATA  = 32'h0000_0000;
        end else begin
            if (ar_sel == 1'b0) begin
                M_RVALID = S0_RVALID;
                M_RRESP  = S0_RRESP;
                M_RDATA  = S0_RDATA;
            end else begin
                M_RVALID = S1_RVALID;
                M_RRESP  = S1_RRESP;
                M_RDATA  = S1_RDATA;
            end
        end
    end

endmodule
