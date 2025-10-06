// ===== ADICIONADO: Comentários explicativos automáticos =====
// Este arquivo recebeu um bloco de comentários adicionais para
// auxiliar na simulação e entendimento. (picorv32.v foi mantido
// sem alterações por sua solicitação.)
// Você pode remover este bloco se preferir comentários mais curtos.

module axi_lite_stub(
    input  wire        aclk,
    input  wire        aresetn,
    // AXI4-Lite Slave
    input  wire [31:0] S_AWADDR,
    input  wire [2:0]  S_AWPROT,
    input  wire        S_AWVALID,
    output reg         S_AWREADY,

    input  wire [31:0] S_WDATA,
    input  wire [3:0]  S_WSTRB,
    input  wire        S_WVALID,
    output reg         S_WREADY,

    output reg  [1:0]  S_BRESP,
    output reg         S_BVALID,
    input  wire        S_BREADY,

    input  wire [31:0] S_ARADDR,
    input  wire [2:0]  S_ARPROT,
    input  wire        S_ARVALID,
    output reg         S_ARREADY,

    output reg  [31:0] S_RDATA,
    output reg  [1:0]  S_RRESP,
    output reg         S_RVALID,
    input  wire        S_RREADY
);
    always @(posedge aclk) begin
        if (!aresetn) begin
            S_AWREADY <= 1'b0;
            S_WREADY  <= 1'b0;
            S_BVALID  <= 1'b0;
            S_BRESP   <= 2'b00;

            S_ARREADY <= 1'b0;
            S_RVALID  <= 1'b0;
            S_RRESP   <= 2'b00;
            S_RDATA   <= 32'hACCE55ED; // <-- valor hexa válido
        end else begin
            // WRITE channel (AW/W/B)
            if (!S_AWREADY) S_AWREADY <= S_AWVALID;
            if (!S_WREADY)  S_WREADY  <= S_WVALID;
            if ((S_AWREADY && S_AWVALID) && (S_WREADY && S_WVALID) && !S_BVALID) begin
                S_BRESP  <= 2'b00; // OKAY
                S_BVALID <= 1'b1;
                S_AWREADY <= 1'b0;
                S_WREADY  <= 1'b0;
            end
            if (S_BVALID && S_BREADY) S_BVALID <= 1'b0;

            // READ channel (AR/R)
            if (!S_ARREADY) S_ARREADY <= S_ARVALID;
            if (S_ARREADY && S_ARVALID && !S_RVALID) begin
                S_RDATA  <= 32'hACCE55ED;
                S_RRESP  <= 2'b00; // OKAY
                S_RVALID <= 1'b1;
                S_ARREADY <= 1'b0;
            end
            if (S_RVALID && S_RREADY) S_RVALID <= 1'b0;
        end
    end
endmodule
