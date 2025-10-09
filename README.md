# 🧩 PicoRV32 AXI SoC Full

Este projeto implementa um **System-on-Chip (SoC)** completo baseado no processador **PicoRV32** integrado a uma **interconexão AXI4-Lite**, com **memória RAM**, **periféricos GPIO** e uma **testbench completa** para simulação e verificação funcional.

---

## 🏗️ Estrutura do Projeto

```
PL_picorv32_axi_with_hex_tb/
├── src/
│   ├── soc_top_picorv32_axi.v        # Módulo de topo do SoC
│   ├── mem_subsystem_axi.v           # Sub-sistema de memória (AXI RAM)
│   ├── periph_subsystem_axi.v        # Sub-sistema de periféricos (GPIO)
│   ├── gpio_axi.v                    # Controlador AXI GPIO
│   ├── axi_lite_1to2_decoder.v       # Decodificador AXI 1 para 2
│   ├── axi_lite_1toN_decoder.v       # Decodificador genérico AXI 1 para N
│   ├── axi_lite_stub.v               # Módulo AXI de debug / placeholder
│   ├── picorv32.v                    # Núcleo RISC-V PicoRV32 (sem comentários adicionais)
├── test/
│   ├── tb_soc_full_test.v            # Testbench principal
│   ├── firmware.hex                  # Programa de teste (memória inicial)
└── README.md
```

---

## ⚙️ Descrição dos Principais Módulos

### 🔹 `soc_top_picorv32_axi.v`
Integra o processador PicoRV32, o subsistema de memória e o subsistema de periféricos, conectados por uma interconexão **AXI4-Lite**.  
Fornece a hierarquia principal de interconexão e o mapeamento de endereços.

### 🔹 `mem_subsystem_axi.v`
Implementa a memória principal do sistema, compatível com protocolo **AXI4-Lite**, e carrega o conteúdo inicial do arquivo `firmware.hex`.

### 🔹 `periph_subsystem_axi.v`
Gerencia os periféricos mapeados em memória, como GPIO.  
Permite que o processador realize leituras e escritas para controle de E/S.

### 🔹 `tb_soc_full_test.v`
Testbench que:
- Gera **clock e reset**;
- Carrega o **firmware.hex** na RAM;
- Monitora as transações AXI de leitura e escrita;
- Valida se os dados iniciais foram carregados corretamente;
- Registra atividade AXI no console e gera o arquivo **.vcd** para análise em waveform.

---

## 🔬 Firmware de Teste (`firmware.hex`)

Arquivo em formato hexadecimal carregado automaticamente na RAM.  
Representa um programa mínimo que realiza operações de leitura e escrita na memória e periféricos:

```
a5a5a2b7
5a528293
10000337
00030313
00532023
000002b7
05528293
20000337
00030313
00532023
deadc2b7
eef28293
30000337
00030313
00532023
010202b7
30428293
40000337
00030313
00532023
000002b7
00128293
50000337
00030313
00532023
10000337
00030313
00032383
00000337
00030313
00732023
20000337
00030313
00032403
00000337
00430313
00832023
000004b7
00548493
fff48493
fe048ce3
00100073
```

O que esse firmware faz (resumo, passo a passo)

O programa usa instruções RV32I simples (LUI + ADDI para formar endereços/imediatos, SW/LW para acessar MMIO, e um pequeno loop) e realiza as seguintes ações na ordem:

GPIO

Escreve a palavra 0xA5A5A5A5 para GPIO_BASE + 0x0 (0x1000_0000).

Em seguida lê GPIO_BASE + 0x0 para um registrador (lêback).

UART

Escreve a palavra 0x00000055 para UART_BASE + 0x0 (0x2000_0000).

Em seguida lê UART_BASE + 0x0 (status/data) e salva o resultado na RAM (em RAM_BASE + 4) para inspeção.

SPI

Escreve 0xDEADBEEF para SPI_BASE + 0x0 (0x3000_0000).

I2C

Escreve 0x01020304 para I2C_BASE + 0x0 (0x4000_0000).

TIMER

Escreve 0x1 para TIMER_BASE + 0x0 (0x5000_0000) (ex.: iniciar o timer).

Verificação em RAM

Lê de GPIO_BASE e armazena a leitura em RAM_BASE + 0x0.

Lê de UART_BASE e armazena a leitura em RAM_BASE + 0x4.

Loop de espera

Um pequeno contador (valor 5) é decrementado em loop (apenas para consumir tempo; ajuda a produzir atividade temporalmente observável nos periféricos), depois o programa executa ebreak para finalizar/entrar em depuração.

---

## ▶️ Simulação

### 🧰 Usando Icarus Verilog
```bash
iverilog -g2005 -o tb.vvp   sim/tb_soc_full_test.v   rtl/*.v
vvp tb.vvp
```

Após a simulação:
- O terminal exibirá o resultado das validações automáticas;
- O arquivo `tb_soc_full_test.vcd` será gerado (abra no GTKWave).

### 🧰 Usando Verilator
```bash
verilator -Wall --cc --exe sim/tb_soc_full_test.v rtl/*.v   --top-module tb_soc_full_test --build
./obj_dir/Vtb_soc_full_test
```

---

## 📊 Saída Esperada

Durante a simulação, você deverá observar:
- Mensagens confirmando a carga do `firmware.hex`;
- Transações AXI de leitura/escrita sendo realizadas;
- Nenhum erro ou falha (`$fatal`) durante a execução;
- O sinal `gpio_out` alternando conforme as operações do programa.

---
