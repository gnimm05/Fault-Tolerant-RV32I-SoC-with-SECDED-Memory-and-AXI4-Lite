`timescale 1ns / 1ps

module mem_stage (
    input  logic        clk,
    input  logic        reset_n,

    // From EX/MEM
    input  logic        ex_mem_reg_write,
    input  logic [1:0]  ex_mem_result_src,
    input  logic        ex_mem_mem_write,
    input  logic        ex_mem_mem_read,
    input  logic [31:0] ex_mem_alu_result,
    input  logic [31:0] ex_mem_write_data,
    input  logic [4:0]  ex_mem_rd,
    input  logic [31:0] ex_mem_pc_plus_4,

    // Data Memory interface
    output logic [31:0] dmem_addr,
    output logic [31:0] dmem_wdata,
    output logic        dmem_we,
    output logic        dmem_re,
    input  logic [31:0] dmem_rdata,

    // MEM/WB output
    output logic        mem_wb_reg_write,
    output logic [1:0]  mem_wb_result_src,
    output logic [31:0] mem_wb_alu_result,
    output logic [31:0] mem_wb_read_data,
    output logic [4:0]  mem_wb_rd,
    output logic [31:0] mem_wb_pc_plus_4
);

    // Pass-through to Memory
    assign dmem_addr  = ex_mem_alu_result;
    assign dmem_wdata = ex_mem_write_data;
    assign dmem_we    = ex_mem_mem_write;
    assign dmem_re    = ex_mem_mem_read;

    // MEM/WB Pipeline Register
    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            mem_wb_reg_write  <= 1'b0;
            mem_wb_result_src <= 2'b0;
            mem_wb_alu_result <= 32'b0;
            mem_wb_read_data  <= 32'b0;
            mem_wb_rd         <= 5'b0;
            mem_wb_pc_plus_4  <= 32'b0;
        end else begin
            mem_wb_reg_write  <= ex_mem_reg_write;
            mem_wb_result_src <= ex_mem_result_src;
            mem_wb_alu_result <= ex_mem_alu_result;
            mem_wb_read_data  <= dmem_rdata;
            mem_wb_rd         <= ex_mem_rd;
            mem_wb_pc_plus_4  <= ex_mem_pc_plus_4;
        end
    end

endmodule
