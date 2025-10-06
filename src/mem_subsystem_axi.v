// ===== ADICIONADO: Comentários explicativos automáticos =====
// Este arquivo recebeu um bloco de comentários adicionais para
// auxiliar na simulação e entendimento. (picorv32.v foi mantido
// sem alterações por sua solicitação.)
// Você pode remover este bloco se preferir comentários mais curtos.

`timescale 1ns/1ps
// ============================================================================
// mem_subsystem_axi.v  (AXI4-Lite RAM Slave)
// - RAM parametrizável (BYTES)
// - Preload seguro com JAL x0,0 (0x0000006F) para gerar fetch sem firmware
// - $readmemh("firmware.hex") opcional (desligue com +nofw)
// - Protocolo AXI4-Lite "subset": sem BRESP/RRESP no lado slave
// ============================================================================

module mem_subsystem_axi #(
  parameter integer BYTES = 64*1024
)(
  input  wire        aclk,
  input  wire        aresetn,

  // AXI4-Lite Slave Interface (sem *RESP)
  input  wire [31:0] S_AWADDR,
  input  wire  [2:0] S_AWPROT,
  input  wire        S_AWVALID,
  output wire        S_AWREADY,

  input  wire [31:0] S_WDATA,
  input  wire  [3:0] S_WSTRB,
  input  wire        S_WVALID,
  output wire        S_WREADY,

  output reg         S_BVALID,
  input  wire        S_BREADY,

  input  wire [31:0] S_ARADDR,
  input  wire  [2:0] S_ARPROT,
  input  wire        S_ARVALID,
  output wire        S_ARREADY,

  output reg  [31:0] S_RDATA,
  output reg         S_RVALID,
  input  wire        S_RREADY
);

  // ==========================================================================
  // RAM
  // ==========================================================================
  localparam integer WORDS     = BYTES/4;
  localparam integer ADDR_BITS = (BYTES <= 4) ? 2 :
                                 (BYTES <= 8) ? 3 : $clog2(BYTES);

  reg [31:0] mem [0:WORDS-1];

  // Preload seguro + firmware.hex (se disponível e sem +nofw)
  integer i;
  initial begin
    // 1) Preenche toda a RAM com "JAL x0, 0" → 0x0000006F
    for (i = 0; i < WORDS; i = i + 1)
      mem[i] = 32'h0000_006F;

    // 2) Se não houver +nofw, tenta sobrepor com firmware.hex
    if (!$test$plusargs("nofw")) begin
      $display("[%0t] mem_subsystem_axi: tentando carregar firmware.hex...", $time);
      // Se o arquivo existir, ele sobrescreve o preload acima nas palavras presentes.
      $readmemh("firmware.hex", mem);
    end
  end

  // ==========================================================================
  // AXI4-Lite — Política de handshake
  // - AWREADY/WREADY/ARREADY sempre '1' (aceitação imediata)
  // - BVALID sobe 1 ciclo após AW/W (quando ambos ocorrerem) até BREADY
  // - RVALID sobe 1 ciclo após AR até RREADY (latência de 1 ciclo)
  // ==========================================================================

  // READY sempre alto (aceita transações a qualquer ciclo)
  assign S_AWREADY = 1'b1;
  assign S_WREADY  = 1'b1;
  assign S_ARREADY = 1'b1;

  // ==========================================================================
  // Escrita (AW+W) → BVALID
  // ==========================================================================
  // Captura write quando ambos canais chegam válidos no mesmo ciclo.
  wire do_write = S_AWVALID && S_WVALID; // com READY=1, o handshake ocorre imediatamente

  // Função de escrita com máscara de byte (WSTRB)
  function [31:0] apply_wstrb;
    input [31:0] oldw;
    input [31:0] neww;
    input [3:0]  wstrb;
    begin
      apply_wstrb[ 7: 0] = wstrb[0] ? neww[ 7: 0] : oldw[ 7: 0];
      apply_wstrb[15: 8] = wstrb[1] ? neww[15: 8] : oldw[15: 8];
      apply_wstrb[23:16] = wstrb[2] ? neww[23:16] : oldw[23:16];
      apply_wstrb[31:24] = wstrb[3] ? neww[31:24] : oldw[31:24];
    end
  endfunction

  // Índice de palavra (alinhamento a 32 bits)
  wire [ADDR_BITS-1:2] aw_word = S_AWADDR[ADDR_BITS-1:2];

  always @(posedge aclk) begin
    if (!aresetn) begin
      S_BVALID <= 1'b0;
    end else begin
      // Conclui resposta de write quando master aceita
      if (S_BVALID && S_BREADY)
        S_BVALID <= 1'b0;

      // Realiza escrita quando ambos válidos; gera BVALID
      if (do_write) begin
        // Guarda somente se dentro do range
        if (aw_word < WORDS) begin
          mem[aw_word] <= apply_wstrb(mem[aw_word], S_WDATA, S_WSTRB);
        end
        S_BVALID <= 1'b1;
      end
    end
  end

  // ==========================================================================
  // Leitura (AR) → RDATA/RVALID
  // ==========================================================================
  reg [ADDR_BITS-1:2] ar_word_q;

  // Captura endereço de leitura quando ARVALID (READY=1)
  always @(posedge aclk) begin
    if (!aresetn) begin
      ar_word_q <= { (ADDR_BITS-2){1'b0} };
    end else if (S_ARVALID) begin
      ar_word_q <= S_ARADDR[ADDR_BITS-1:2];
    end
  end

  // Latência de 1 ciclo: RVALID sobe no ciclo seguinte ao ARVALID
  always @(posedge aclk) begin
    if (!aresetn) begin
      S_RVALID <= 1'b0;
      S_RDATA  <= 32'h0000_0000;
    end else begin
      // Quando master aceita, derruba RVALID
      if (S_RVALID && S_RREADY)
        S_RVALID <= 1'b0;

      // Se houve ARVALID neste ciclo, responde no próximo
      if (S_ARVALID) begin
        // Proteção de faixa
        if (S_ARADDR[ADDR_BITS-1:2] < WORDS)
          S_RDATA <= mem[S_ARADDR[ADDR_BITS-1:2]];
        else
          S_RDATA <= 32'h0000_0000; // fora de faixa → retorna zero

        S_RVALID <= 1'b1;
      end
    end
  end

  // ==========================================================================
  // Sinais não usados (somente para evitar warnings)
  // ==========================================================================
  // PROT não influencia comportamento nesta RAM
  // (mantidos para compatibilidade de interface)
  /* verilator lint_off UNUSED */
  wire [2:0] _unused_prot_aw = S_AWPROT;
  wire [2:0] _unused_prot_ar = S_ARPROT;
  /* verilator lint_on UNUSED */

endmodule
