// ===== ADICIONADO: Comentários explicativos automáticos =====
// Este arquivo recebeu um bloco de comentários adicionais para
// auxiliar na simulação e entendimento. (picorv32.v foi mantido
// sem alterações por sua solicitação.)
// Você pode remover este bloco se preferir comentários mais curtos.

// ============================================================================
// gpio_axi.v  - GPIO AXI4-Lite com DIR/OUT/IN
// Regmap (offsets de 4 bytes):
//  0x00 DIR  (1=output, 0=input)   RW
//  0x04 OUT  (valor pinos out)     RW
//  0x08 IN   (leitura pinos in)    RO
// ============================================================================
module gpio_axi #(
    parameter integer WIDTH = 16
)(
    input  wire aclk, input wire aresetn,
    // AXI-Lite Slave
    input  wire [31:0] S_AWADDR, input wire [2:0] S_AWPROT, input wire S_AWVALID, output reg  S_AWREADY,
    input  wire [31:0] S_WDATA,  input wire [3:0] S_WSTRB,  input wire S_WVALID,  output reg  S_WREADY,
    output reg  [1:0]  S_BRESP,  output reg  S_BVALID,      input  wire S_BREADY,
    input  wire [31:0] S_ARADDR, input wire [2:0] S_ARPROT, input wire S_ARVALID, output reg  S_ARREADY,
    output reg  [31:0] S_RDATA,  output reg  [1:0] S_RRESP, output reg  S_RVALID,  input  wire S_RREADY,
    // IOs
    input  wire [WIDTH-1:0] gpio_in,
    output wire [WIDTH-1:0] gpio_out,
    output wire [WIDTH-1:0] gpio_oe
);
    reg [WIDTH-1:0] dir_reg;   // 1=out
    reg [WIDTH-1:0] out_reg;

    assign gpio_out = out_reg;
    assign gpio_oe  = dir_reg;

    // Write FSM
    reg aw_seen, w_seen;
    reg [31:0] awaddr_latched;

    wire [3:0] aw_off = awaddr_latched[5:2]; // 16B window

    always @(posedge aclk) begin
        if (!aresetn) begin
            S_AWREADY<=0; S_WREADY<=0; S_BVALID<=0; S_BRESP<=2'b00;
            aw_seen<=0; w_seen<=0; awaddr_latched<=32'h0;
            dir_reg <= {WIDTH{1'b0}}; out_reg <= {WIDTH{1'b0}};
        end else begin
            // AW
            if (!S_AWREADY && !aw_seen) begin
                S_AWREADY <= S_AWVALID;
                if (S_AWVALID) begin
                    awaddr_latched <= S_AWADDR;
                    aw_seen <= 1'b1;
                end
            end
            // W
            if (!S_WREADY && !w_seen) begin
                S_WREADY <= S_WVALID;
                if (S_WVALID) w_seen <= 1'b1;
            end
            // Quando ambos vistos → write & BRESP
            if (aw_seen && w_seen && !S_BVALID) begin
                case (aw_off)
                    4'h0: dir_reg <= write_mask(WIDTH, dir_reg, S_WDATA, S_WSTRB);
                    4'h1: out_reg <= write_mask(WIDTH, out_reg, S_WDATA, S_WSTRB);
                    default: ; // ignorar
                endcase
                S_BRESP  <= 2'b00; S_BVALID <= 1'b1;
                S_AWREADY<= 1'b0;  S_WREADY <= 1'b0;
                aw_seen  <= 1'b0;  w_seen   <= 1'b0;
            end
            if (S_BVALID && S_BREADY) S_BVALID <= 1'b0;
        end
    end

    // Read
    always @(posedge aclk) begin
        if (!aresetn) begin
            S_ARREADY<=0; S_RVALID<=0; S_RRESP<=2'b00; S_RDATA<=32'h0;
        end else begin
            if (!S_ARREADY) S_ARREADY <= S_ARVALID;
            if (S_ARREADY && S_ARVALID && !S_RVALID) begin
                case (S_ARADDR[5:2])
                    4'h0: S_RDATA <= {{(32-WIDTH){1'b0}}, dir_reg};
                    4'h1: S_RDATA <= {{(32-WIDTH){1'b0}}, out_reg};
                    4'h2: S_RDATA <= {{(32-WIDTH){1'b0}}, gpio_in};
                    default: S_RDATA <= 32'h0;
                endcase
                S_RRESP <= 2'b00; S_RVALID <= 1'b1; S_ARREADY <= 1'b0;
            end
            if (S_RVALID && S_RREADY) S_RVALID <= 1'b0;
        end
    end

    // Função utilitária: aplica WSTRB
    function [WIDTH-1:0] write_mask;
        input integer W;
        input [WIDTH-1:0] oldv;
        input [31:0] wdata;
        input [3:0] wstrb;
        reg [31:0] merged;
    begin
        merged = oldv;
        if (wstrb[0]) merged[7:0]   = wdata[7:0];
        if (wstrb[1]) merged[15:8]  = wdata[15:8];
        if (wstrb[2]) merged[23:16] = wdata[23:16];
        if (wstrb[3]) merged[31:24] = wdata[31:24];
        write_mask = merged[WIDTH-1:0];
    end
    endfunction
endmodule
