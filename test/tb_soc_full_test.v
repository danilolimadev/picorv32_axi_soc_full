// tb_soc_full_test.v
// Testbench Geral para soc_top_picorv32_axi
// Compatível com Verilog-2001 (Icarus / ModelSim / Vivado)
// - Usa as portas: aclk, aresetn, gpio_in[15:0], gpio_out[15:0], gpio_oe[15:0], cpu_trap
// - Verifica conteúdo inicial da RAM (acesso hierárquico a `uut.u_mem.mem[]`)
// - Monitora algumas transações/atividades internas (se expostas hierarquicamente)
// ------------------------------------------------------------------------------

`timescale 1ns / 1ps

module tb_soc_full_test;

    // -----------------------------------------------------------------
    // sinais de top-level do testbench (mapear para os nomes do módulo)
    // -----------------------------------------------------------------
    reg         aclk;
    reg         aresetn;

    reg [15:0]  gpio_in;
    wire [15:0] gpio_out;
    wire [15:0] gpio_oe;

    wire        cpu_trap;

    // -----------------------------------------------------------------
    // Instância do SoC (use os nomes de porta exatos que você informou)
    // -----------------------------------------------------------------
    soc_top_picorv32_axi uut (
        .aclk      (aclk),
        .aresetn   (aresetn),
        .gpio_in   (gpio_in),
        .gpio_out  (gpio_out),
        .gpio_oe   (gpio_oe),
        .cpu_trap  (cpu_trap)
    );

    // -----------------------------------------------------------------
    // Clock: 100 MHz -> period = 10 ns
    // -----------------------------------------------------------------
    initial aclk = 0;
    always #5 aclk = ~aclk;

    // -----------------------------------------------------------------
    // Reset e sinais iniciais
    // -----------------------------------------------------------------
    initial begin
        aresetn = 0;        // reset ativo baixo
        gpio_in = 16'h0000; // entradas GPIO em zero por padrão
        #100;
        aresetn = 1;        // libera reset
    end

    // -----------------------------------------------------------------
    // Dump VCD para análise de waveform
    // -----------------------------------------------------------------
    initial begin
        $display("=== TB: iniciando simulação ===");
        $dumpfile("tb_soc_full_test.vcd");
        $dumpvars(0, tb_soc_full_test);
    end

    // -----------------------------------------------------------------
    // Watchdog: evita simulação infinita (fecha com erro se ultrapassar tempo)
    // -----------------------------------------------------------------
    initial begin
        #2000000; // 2 ms (em tempo simulado)
        $display("[TB] Watchdog: tempo limite atingido - finalizando.");
        $finish;
    end

    // -----------------------------------------------------------------
    // Após reset, chama verificação de firmware (tarefa)
    // -----------------------------------------------------------------
    initial begin
        // aguarda fim do reset (posedge de aresetn)
        @(posedge aresetn);
        #50;
        $display("[TB] Reset liberado. Iniciando verificações...");
        check_firmware_load();
        $display("[TB] check_firmware_load finalizado. Monitores ativos.");
        // não finalizamos aqui; monitors rodam em other initial blocks
    end

    // ================================================================
    // Tarefa: verifica conteúdo inicial da RAM
    // Observação: isto usa acesso hierárquico à memória interna do SoC.
    // Ajuste o caminho `uut.u_mem.mem` caso a RAM interna tenha outro nome.
    // ================================================================
    task check_firmware_load;
        integer i;
        reg [31:0] expected [0:8];
        reg [31:0] read_val;
        begin
            // valores esperados (você forneceu essas linhas em firmware.hex)
            expected[0] = 32'h100000b7;
            expected[1] = 32'h05500113;
            expected[2] = 32'h0020a023;
            expected[3] = 32'h0aa00193;
            expected[4] = 32'h1030a023;
            expected[5] = 32'h1000a203;
            expected[6] = 32'h2040a023;
            expected[7] = 32'h3040a023;
            expected[8] = 32'h7fdff06f;

            $display("[TB] Verificando conteúdo inicial da RAM por hierarquia...");
            #20;

            // ATENÇÃO:
            // Aqui assumimos que a memória interna do SoC é visível por
            // `uut.u_mem.mem[index]`. Se o seu módulo RAM tiver outro nome
            // hierárquico, substitua `u_mem.mem` pelo caminho correto.
            for (i = 0; i < 9; i = i + 1) begin
                // leitura hierárquica direto da memória (elaboração deve aceitar o caminho)
                read_val = uut.u_mem.mem[i];

                if (read_val !== expected[i]) begin
                    $display("[ERRO] Mem[%0d] = %h (esperado %h)", i, read_val, expected[i]);
                    $fatal; // encerra simulação com erro
                end else begin
                    $display("[OK] Mem[%0d] = %h", i, read_val);
                end
            end

            $display("[TB] Firmware carregado corretamente (primeiras 9 palavras).");
        end
    endtask

    // ================================================================
    // Monitores paralelos (cada um em seu initial -> rodam simultaneamente)
    // Observação: os sinais internos monitorados (S0_AWVALID, etc.) devem
    // existir na hierarquia do seu design para que esses monitores funcionem.
    // Se os nomes internos forem diferentes, ajuste os caminhos abaixo.
    // ================================================================

    // Monitor de escritas para RAM (AWVALID)
    initial begin
        // Proteção: se sinal não existir, a simulação dará erro de elaboração.
        // Assumimos que a hierarquia expõe algo como uut.S0_AWVALID / S0_AWADDR
        forever begin
            @(posedge uut.S0_AWVALID);
            $display("[AXI-RAM] AWVALID pulso detectado @ %0t - AWADDR = 0x%h AWDATA = 0x%h",
                     $time, uut.S0_AWADDR, uut.S0_WDATA);
        end
    end

    // Monitor de escritas para periféricos (S1_AWVALID)
    initial begin
        forever begin
            @(posedge uut.S1_AWVALID);
            $display("[AXI-PERIPH] AWVALID pulso detectado @ %0t - AWADDR = 0x%h AWDATA = 0x%h",
                     $time, uut.S1_AWADDR, uut.S1_WDATA);
        end
    end

    // Monitor de leituras (ARVALID)
    initial begin
        forever begin
            @(posedge uut.S0_ARVALID);
            $display("[AXI-RAM] ARVALID pulso detectado @ %0t - ARADDR = 0x%h",
                     $time, uut.S0_ARADDR);
        end
    end

    // Monitor simples do GPIO (mostra alterações)
    reg [15:0] last_gpio_out;
    initial begin
        last_gpio_out = 16'hXXXX;
        forever begin
            @(posedge aclk);
            if (gpio_out !== last_gpio_out) begin
                $display("[GPIO] gpio_out mudou @ %0t : %h (gpio_oe=%h)", $time, gpio_out, gpio_oe);
                last_gpio_out = gpio_out;
            end
        end
    end

    // Monitor do cpu_trap (se for usado pelo seu firmware)
    initial begin
        forever begin
            @(posedge cpu_trap);
            $display("[CPU_TRAP] cpu_trap asserted @ %0t", $time);
        end
    end

endmodule
