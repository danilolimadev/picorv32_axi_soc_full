// ===== ADICIONADO: Comentários explicativos automáticos =====
// Este arquivo recebeu um bloco de comentários adicionais para
// auxiliar na simulação e entendimento. (picorv32.v foi mantido
// sem alterações por sua solicitação.)
// Você pode remover este bloco se preferir comentários mais curtos.

// ============================================================================
// axi_lite_1toN_decoder.v
// AXI4-Lite Interconnect 1 -> 4
// Versão combinacional para evitar travas em simulação
// ============================================================================

module axi_lite_1toN_decoder #(
    parameter integer N = 4,
    // Endereços base e máscaras (um-hot decoding)
    parameter [N*32-1:0] BASE = {
        32'h4000_3000, 32'h4000_2000, 32'h4000_1000, 32'h4000_0000
    },
    parameter [N*32-1:0] MASK = {
        32'hFFFF_F000, 32'hFFFF_F000, 32'hFFFF_F000, 32'hFFFF_F000
    }
)(
    input  wire aclk,
    input  wire aresetn,

    // ---------------- Master side ----------------
    input  wire [31:0] M_AWADDR,
    input  wire [2:0]  M_AWPROT,
    input  wire        M_AWVALID,
    output wire        M_AWREADY,

    input  wire [31:0] M_WDATA,
    input  wire [3:0]  M_WSTRB,
    input  wire        M_WVALID,
    output wire        M_WREADY,

    output reg  [1:0]  M_BRESP,
    output reg         M_BVALID,
    input  wire        M_BREADY,

    input  wire [31:0] M_ARADDR,
    input  wire [2:0]  M_ARPROT,
    input  wire        M_ARVALID,
    output wire        M_ARREADY,

    output reg  [31:0] M_RDATA,
    output reg  [1:0]  M_RRESP,
    output reg         M_RVALID,
    input  wire        M_RREADY,

    // ---------------- Slave 0 ----------------
    output wire [31:0] S0_AWADDR, output wire [2:0] S0_AWPROT, output wire S0_AWVALID, input  wire S0_AWREADY,
    output wire [31:0] S0_WDATA,  output wire [3:0] S0_WSTRB,  output wire S0_WVALID,  input  wire S0_WREADY,
    input  wire [1:0]  S0_BRESP,  input  wire S0_BVALID,      output wire S0_BREADY,
    output wire [31:0] S0_ARADDR, output wire [2:0] S0_ARPROT, output wire S0_ARVALID, input  wire S0_ARREADY,
    input  wire [31:0] S0_RDATA,  input  wire [1:0] S0_RRESP,  input  wire S0_RVALID,  output wire S0_RREADY,

    // ---------------- Slave 1 ----------------
    output wire [31:0] S1_AWADDR, output wire [2:0] S1_AWPROT, output wire S1_AWVALID, input  wire S1_AWREADY,
    output wire [31:0] S1_WDATA,  output wire [3:0] S1_WSTRB,  output wire S1_WVALID,  input  wire S1_WREADY,
    input  wire [1:0]  S1_BRESP,  input  wire S1_BVALID,      output wire S1_BREADY,
    output wire [31:0] S1_ARADDR, output wire [2:0] S1_ARPROT, output wire S1_ARVALID, input  wire S1_ARREADY,
    input  wire [31:0] S1_RDATA,  input  wire [1:0] S1_RRESP,  input  wire S1_RVALID,  output wire S1_RREADY,

    // ---------------- Slave 2 ----------------
    output wire [31:0] S2_AWADDR, output wire [2:0] S2_AWPROT, output wire S2_AWVALID, input  wire S2_AWREADY,
    output wire [31:0] S2_WDATA,  output wire [3:0] S2_WSTRB,  output wire S2_WVALID,  input  wire S2_WREADY,
    input  wire [1:0]  S2_BRESP,  input  wire S2_BVALID,      output wire S2_BREADY,
    output wire [31:0] S2_ARADDR, output wire [2:0] S2_ARPROT, output wire S2_ARVALID, input  wire S2_ARREADY,
    input  wire [31:0] S2_RDATA,  input  wire [1:0] S2_RRESP,  input  wire S2_RVALID,  output wire S2_RREADY,

    // ---------------- Slave 3 ----------------
    output wire [31:0] S3_AWADDR, output wire [2:0] S3_AWPROT, output wire S3_AWVALID, input  wire S3_AWREADY,
    output wire [31:0] S3_WDATA,  output wire [3:0] S3_WSTRB,  output wire S3_WVALID,  input  wire S3_WREADY,
    input  wire [1:0]  S3_BRESP,  input  wire S3_BVALID,      output wire S3_BREADY,
    output wire [31:0] S3_ARADDR, output wire [2:0] S3_ARPROT, output wire S3_ARVALID, input  wire S3_ARREADY,
    input  wire [31:0] S3_RDATA,  input  wire [1:0] S3_RRESP,  input  wire S3_RVALID,  output wire S3_RREADY
);

    // ---------- Decodificação ----------
    wire sel_aw0 = ((M_AWADDR & MASK[ 0*32 +: 32]) == BASE[ 0*32 +: 32]);
    wire sel_aw1 = ((M_AWADDR & MASK[ 1*32 +: 32]) == BASE[ 1*32 +: 32]);
    wire sel_aw2 = ((M_AWADDR & MASK[ 2*32 +: 32]) == BASE[ 2*32 +: 32]);
    wire sel_aw3 = ((M_AWADDR & MASK[ 3*32 +: 32]) == BASE[ 3*32 +: 32]);

    wire sel_ar0 = ((M_ARADDR & MASK[ 0*32 +: 32]) == BASE[ 0*32 +: 32]);
    wire sel_ar1 = ((M_ARADDR & MASK[ 1*32 +: 32]) == BASE[ 1*32 +: 32]);
    wire sel_ar2 = ((M_ARADDR & MASK[ 2*32 +: 32]) == BASE[ 2*32 +: 32]);
    wire sel_ar3 = ((M_ARADDR & MASK[ 3*32 +: 32]) == BASE[ 3*32 +: 32]);

    // ---------- WRITE ----------
    assign S0_AWADDR = M_AWADDR; assign S0_AWPROT = M_AWPROT; assign S0_AWVALID = M_AWVALID & sel_aw0;
    assign S1_AWADDR = M_AWADDR; assign S1_AWPROT = M_AWPROT; assign S1_AWVALID = M_AWVALID & sel_aw1;
    assign S2_AWADDR = M_AWADDR; assign S2_AWPROT = M_AWPROT; assign S2_AWVALID = M_AWVALID & sel_aw2;
    assign S3_AWADDR = M_AWADDR; assign S3_AWPROT = M_AWPROT; assign S3_AWVALID = M_AWVALID & sel_aw3;

    assign M_AWREADY = (sel_aw0 ? S0_AWREADY : 1'b0) |
                       (sel_aw1 ? S1_AWREADY : 1'b0) |
                       (sel_aw2 ? S2_AWREADY : 1'b0) |
                       (sel_aw3 ? S3_AWREADY : 1'b0);

    assign S0_WDATA = M_WDATA; assign S0_WSTRB = M_WSTRB; assign S0_WVALID = M_WVALID & sel_aw0;
    assign S1_WDATA = M_WDATA; assign S1_WSTRB = M_WSTRB; assign S1_WVALID = M_WVALID & sel_aw1;
    assign S2_WDATA = M_WDATA; assign S2_WSTRB = M_WSTRB; assign S2_WVALID = M_WVALID & sel_aw2;
    assign S3_WDATA = M_WDATA; assign S3_WSTRB = M_WSTRB; assign S3_WVALID = M_WVALID & sel_aw3;

    assign M_WREADY = (sel_aw0 ? S0_WREADY : 1'b0) |
                      (sel_aw1 ? S1_WREADY : 1'b0) |
                      (sel_aw2 ? S2_WREADY : 1'b0) |
                      (sel_aw3 ? S3_WREADY : 1'b0);

    assign S0_BREADY = M_BREADY;
    assign S1_BREADY = M_BREADY;
    assign S2_BREADY = M_BREADY;
    assign S3_BREADY = M_BREADY;

    // ---------- BRESP mux ----------
    always @* begin
        M_BVALID = (sel_aw0 & S0_BVALID) | (sel_aw1 & S1_BVALID) |
                   (sel_aw2 & S2_BVALID) | (sel_aw3 & S3_BVALID);
        M_BRESP  = sel_aw0 ? S0_BRESP :
                   sel_aw1 ? S1_BRESP :
                   sel_aw2 ? S2_BRESP :
                   sel_aw3 ? S3_BRESP : 2'b10; // DECERR
    end

    // ---------- READ ----------
    assign S0_ARADDR = M_ARADDR; assign S0_ARPROT = M_ARPROT; assign S0_ARVALID = M_ARVALID & sel_ar0;
    assign S1_ARADDR = M_ARADDR; assign S1_ARPROT = M_ARPROT; assign S1_ARVALID = M_ARVALID & sel_ar1;
    assign S2_ARADDR = M_ARADDR; assign S2_ARPROT = M_ARPROT; assign S2_ARVALID = M_ARVALID & sel_ar2;
    assign S3_ARADDR = M_ARADDR; assign S3_ARPROT = M_ARPROT; assign S3_ARVALID = M_ARVALID & sel_ar3;

    assign M_ARREADY = (sel_ar0 ? S0_ARREADY : 1'b0) |
                       (sel_ar1 ? S1_ARREADY : 1'b0) |
                       (sel_ar2 ? S2_ARREADY : 1'b0) |
                       (sel_ar3 ? S3_ARREADY : 1'b0);

    assign S0_RREADY = M_RREADY;
    assign S1_RREADY = M_RREADY;
    assign S2_RREADY = M_RREADY;
    assign S3_RREADY = M_RREADY;

    // ---------- RDATA mux ----------
    always @* begin
        M_RVALID = (sel_ar0 & S0_RVALID) | (sel_ar1 & S1_RVALID) |
                   (sel_ar2 & S2_RVALID) | (sel_ar3 & S3_RVALID);
        M_RRESP  = sel_ar0 ? S0_RRESP :
                   sel_ar1 ? S1_RRESP :
                   sel_ar2 ? S2_RRESP :
                   sel_ar3 ? S3_RRESP : 2'b10;
        M_RDATA  = sel_ar0 ? S0_RDATA :
                   sel_ar1 ? S1_RDATA :
                   sel_ar2 ? S2_RDATA :
                   sel_ar3 ? S3_RDATA : 32'hDEAD_DEAD;
    end

endmodule
