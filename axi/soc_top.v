module soc_top (
    input  wire clk,
    input  wire resetn
  );
  wire trap;

  wire        mem_axi_awvalid;
  reg         mem_axi_awready;
  wire [31:0] mem_axi_awaddr;
  wire [ 2:0] mem_axi_awprot;

  wire        mem_axi_wvalid;
  reg         mem_axi_wready;
  wire [31:0] mem_axi_wdata;
  wire [ 3:0] mem_axi_wstrb;

  reg         mem_axi_bvalid;
  wire        mem_axi_bready;

  wire        mem_axi_arvalid;
  reg         mem_axi_arready;
  wire [31:0] mem_axi_araddr;
  wire [ 2:0] mem_axi_arprot;

  reg         mem_axi_rvalid;
  wire        mem_axi_rready;
  reg  [31:0] mem_axi_rdata;

  wire        pcpi_valid;
  wire [31:0] pcpi_insn;
  wire [31:0] pcpi_rs1;
  wire [31:0] pcpi_rs2;
  reg         pcpi_wr;
  reg  [31:0] pcpi_rd;
  reg         pcpi_wait;
  reg         pcpi_ready;

  reg  [31:0] irq;
  wire [31:0] eoi;

  wire        trace_valid;
  wire [35:0] trace_data;


  picorv32_axi cpu (
                 .clk(clk),
                 .resetn(resetn),
                 .trap(trap),

                 .mem_axi_awvalid(mem_axi_awvalid),
                 .mem_axi_awready(mem_axi_awready),
                 .mem_axi_awaddr(mem_axi_awaddr),
                 .mem_axi_awprot(mem_axi_awprot),

                 .mem_axi_wvalid(mem_axi_wvalid),
                 .mem_axi_wready(mem_axi_wready),
                 .mem_axi_wdata(mem_axi_wdata),
                 .mem_axi_wstrb(mem_axi_wstrb),

                 .mem_axi_bvalid(mem_axi_bvalid),
                 .mem_axi_bready(mem_axi_bready),

                 .mem_axi_arvalid(mem_axi_arvalid),
                 .mem_axi_arready(mem_axi_arready),
                 .mem_axi_araddr(mem_axi_araddr),
                 .mem_axi_arprot(mem_axi_arprot),

                 .mem_axi_rvalid(mem_axi_rvalid),
                 .mem_axi_rready(mem_axi_rready),
                 .mem_axi_rdata(mem_axi_rdata),

                 .pcpi_valid(pcpi_valid),
                 .pcpi_insn(pcpi_insn),
                 .pcpi_rs1(pcpi_rs1),
                 .pcpi_rs2(pcpi_rs2),
                 .pcpi_wr(pcpi_wr),
                 .pcpi_rd(pcpi_rd),
                 .pcpi_wait(pcpi_wait),
                 .pcpi_ready(pcpi_ready),

                 .irq(irq),
                 .eoi(eoi),

                 .trace_valid(trace_valid),
                 .trace_data(trace_data)
               );


endmodule
