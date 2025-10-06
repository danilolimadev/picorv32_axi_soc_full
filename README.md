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
100000b7
05500113
0020a023
0aa00193
1030a023
1000a203
2040a023
3040a023
7fdff06f
```

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
