`timescale 1ns / 1ps

module soc_top (
    input logic clk,
    input logic reset_n
);

    // CPU Instruction Memory Interface
    logic [31:0] imem_addr;
    logic [31:0] imem_rdata;

    // CPU Data Memory Interface (to Master)
    logic [31:0] cpu_dmem_addr;
    logic [31:0] cpu_dmem_wdata;
    logic        cpu_dmem_we;
    logic        cpu_dmem_re;
    logic [31:0] cpu_dmem_rdata;
    logic        cpu_ready; 

    // AXI4-Lite Interface (Master to Slave)
    logic [31:0] awaddr;
    logic        awvalid, awready;
    logic [31:0] wdata;
    logic [3:0]  wstrb;
    logic        wvalid, wready;
    logic [1:0]  bresp;
    logic        bvalid, bready;
    logic [31:0] araddr;
    logic        arvalid, arready;
    logic [31:0] rdata;
    logic [1:0]  rresp;
    logic        rvalid, rready;

    // Slave to SECDED Controller Interface
    logic [31:0] mem_addr;
    logic [31:0] mem_wdata;
    logic        mem_we, mem_re;
    logic [31:0] mem_rdata;
    logic        single_error, double_error;

    // Instruction ROM for Fetch
    logic [31:0] irom [0:1023];
    always_ff @(posedge clk) begin
        imem_rdata <= irom[imem_addr[31:2]];
    end

    // Component: Core Datapath
    rv32i_core core (
        .clk(clk),
        .reset_n(reset_n),
        .imem_addr(imem_addr),
        .imem_rdata(imem_rdata),
        .dmem_addr(cpu_dmem_addr),
        .dmem_wdata(cpu_dmem_wdata),
        .dmem_we(cpu_dmem_we),
        .dmem_re(cpu_dmem_re),
        .dmem_rdata(cpu_dmem_rdata)
    );

    // Component: AXI4-Lite Master Interface
    axi4_lite_master master (
        .clk(clk),
        .reset_n(reset_n),
        .cpu_addr(cpu_dmem_addr),
        .cpu_wdata(cpu_dmem_wdata),
        .cpu_we(cpu_dmem_we),
        .cpu_re(cpu_dmem_re),
        .cpu_rdata(cpu_dmem_rdata),
        .cpu_ready(cpu_ready),
        
        .awaddr(awaddr), .awvalid(awvalid), .awready(awready),
        .wdata(wdata), .wstrb(wstrb), .wvalid(wvalid), .wready(wready),
        .bresp(bresp), .bvalid(bvalid), .bready(bready),
        .araddr(araddr), .arvalid(arvalid), .arready(arready),
        .rdata(rdata), .rresp(rresp), .rvalid(rvalid), .rready(rready)
    );

    // Component: AXI4-Lite Slave Interface
    axi4_lite_slave slave (
        .clk(clk),
        .reset_n(reset_n),
        
        .awaddr(awaddr), .awvalid(awvalid), .awready(awready),
        .wdata(wdata), .wstrb(wstrb), .wvalid(wvalid), .wready(wready),
        .bresp(bresp), .bvalid(bvalid), .bready(bready),
        .araddr(araddr), .arvalid(arvalid), .arready(arready),
        .rdata(rdata), .rresp(rresp), .rvalid(rvalid), .rready(rready),

        .mem_addr(mem_addr),
        .mem_wdata(mem_wdata),
        .mem_we(mem_we),
        .mem_re(mem_re),
        .mem_rdata(mem_rdata)
    );

    // Component: SECDED Memory Block
    secded_controller #(
        .MEM_SIZE(1024)
    ) mem_ctrl (
        .clk(clk),
        .reset_n(reset_n),
        .addr(mem_addr),
        .wdata(mem_wdata),
        .we(mem_we),
        .re(mem_re),
        .rdata(mem_rdata),
        .single_error(single_error),
        .double_error(double_error)
    );

endmodule
