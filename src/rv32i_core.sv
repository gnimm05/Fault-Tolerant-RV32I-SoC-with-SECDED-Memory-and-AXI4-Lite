`timescale 1ns / 1ps

module rv32i_core (
    input  logic        clk,
    input  logic        reset_n,

    // Instruction Memory
    output logic [31:0] imem_addr,
    input  logic [31:0] imem_rdata,

    // Data Memory
    output logic [31:0] dmem_addr,
    output logic [31:0] dmem_wdata,
    output logic        dmem_we,
    output logic        dmem_re,
    input  logic [31:0] dmem_rdata
);

    // =========================================================================
    // Wires & Signals
    // =========================================================================
    
    // IF Stage
    logic        pc_src;
    logic [31:0] branch_target_addr;
    logic [31:0] pc_plus_4;
    
    // IF/ID Pipeline Register
    logic [31:0] if_id_pc, if_id_instr;
    logic        if_id_flush, if_id_stall;

    // ID Stage
    logic        wb_reg_write;
    logic [4:0]  wb_write_reg;
    logic [31:0] wb_write_data;
    
    logic [31:0] id_ex_pc, id_ex_read_data1, id_ex_read_data2, id_ex_imm;
    logic [4:0]  id_ex_rs1, id_ex_rs2, id_ex_rd;
    logic        id_ex_alu_src_a, id_ex_alu_src_b;
    logic [3:0]  id_ex_alu_control;
    logic        id_ex_mem_write, id_ex_mem_read;
    logic [1:0]  id_ex_result_src;
    logic        id_ex_branch, id_ex_jump, id_ex_reg_write;
    logic [2:0]  id_ex_funct3;
    logic [31:0] id_read_data1_out, id_read_data2_out;
    
    // EX Stage
    logic [1:0]  forward_a, forward_b;
    logic        ex_mem_reg_write, ex_mem_mem_write, ex_mem_mem_read;
    logic [1:0]  ex_mem_result_src;
    logic [31:0] ex_mem_alu_result, ex_mem_write_data;
    logic [4:0]  ex_mem_rd;
    logic [31:0] ex_mem_pc_plus_4;
    
    // MEM Stage
    logic        mem_wb_reg_write;
    logic [1:0]  mem_wb_result_src;
    logic [31:0] mem_wb_alu_result, mem_wb_read_data, mem_wb_pc_plus_4;
    logic [4:0]  mem_wb_rd;

    // Hazard Signals
    logic        stall, flush_id, flush_ex;

    // =========================================================================
    // Hazard Detection Unit
    // =========================================================================
    hazard_detection_unit hdu (
        .id_rs1(if_id_instr[19:15]),
        .id_rs2(if_id_instr[24:20]),
        .id_ex_rd(id_ex_rd),
        .id_ex_mem_read(id_ex_mem_read),
        .pc_src(pc_src), // Branch/Jump taken
        .stall(stall),
        .flush_id_ex(flush_ex),
        .flush_if_id(flush_id)
    );

    // =========================================================================
    // Forwarding Unit
    // =========================================================================
    forwarding_unit fwd (
        .id_ex_rs1(id_ex_rs1),
        .id_ex_rs2(id_ex_rs2),
        .ex_mem_rd(ex_mem_rd),
        .ex_mem_reg_write(ex_mem_reg_write),
        .mem_wb_rd(mem_wb_rd),
        .mem_wb_reg_write(mem_wb_reg_write),
        .forward_a(forward_a),
        .forward_b(forward_b)
    );

    // =========================================================================
    // IF Stage
    // =========================================================================
    if_stage if_inst (
        .clk(clk),
        .reset_n(reset_n),
        .pc_src(pc_src),
        .branch_target_addr(branch_target_addr),
        .instruction_address(imem_addr),
        .pc_plus_4(pc_plus_4)
    );
    
    // IF/ID Pipeline Register
    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            if_id_pc    <= 32'b0;
            if_id_instr <= 32'b0;
        end else if (flush_id) begin // Also flushed on jump/branch taken
            if_id_pc    <= 32'b0;
            if_id_instr <= 32'b0;
        end else if (!stall) begin
            if_id_pc    <= imem_addr;
            if_id_instr <= imem_rdata;
        end
    end

    // =========================================================================
    // ID Stage
    // =========================================================================
    id_stage id_inst (
        .clk(clk),
        .reset_n(reset_n),
        .flush(flush_ex),
        .stall(1'b0), // EX registers stall logic depends on global stall or if we just insert bubble via flush. We insert bubble.
        .if_id_pc(if_id_pc),
        .if_id_instr(if_id_instr),
        
        // Writeback loop
        .wb_reg_write(mem_wb_reg_write),
        .wb_write_reg(mem_wb_rd),
        .wb_write_data(wb_write_data),
        
        // Pipeline outputs
        .id_ex_pc(id_ex_pc),
        .id_ex_read_data1(id_ex_read_data1),
        .id_ex_read_data2(id_ex_read_data2),
        .id_ex_imm(id_ex_imm),
        .id_ex_rs1(id_ex_rs1),
        .id_ex_rs2(id_ex_rs2),
        .id_ex_rd(id_ex_rd),
        .id_ex_alu_src_a(id_ex_alu_src_a),
        .id_ex_alu_src_b(id_ex_alu_src_b),
        .id_ex_alu_control(id_ex_alu_control),
        .id_ex_mem_write(id_ex_mem_write),
        .id_ex_mem_read(id_ex_mem_read),
        .id_ex_result_src(id_ex_result_src),
        .id_ex_branch(id_ex_branch),
        .id_ex_jump(id_ex_jump),
        .id_ex_reg_write(id_ex_reg_write),
        .id_ex_funct3(id_ex_funct3),
        .read_data1_out(id_read_data1_out),
        .read_data2_out(id_read_data2_out)
    );

    // =========================================================================
    // EX Stage
    // =========================================================================
    ex_stage ex_inst (
        .clk(clk),
        .reset_n(reset_n),
        
        // ID/EX Control
        .id_ex_alu_src_a(id_ex_alu_src_a),
        .id_ex_alu_src_b(id_ex_alu_src_b),
        .id_ex_alu_control(id_ex_alu_control),
        .id_ex_mem_write(id_ex_mem_write),
        .id_ex_mem_read(id_ex_mem_read),
        .id_ex_result_src(id_ex_result_src),
        .id_ex_branch(id_ex_branch),
        .id_ex_jump(id_ex_jump),
        .id_ex_reg_write(id_ex_reg_write),
        .id_ex_funct3(id_ex_funct3),
        
        // ID/EX Data
        .id_ex_pc(id_ex_pc),
        .id_ex_read_data1(id_ex_read_data1),
        .id_ex_read_data2(id_ex_read_data2),
        .id_ex_imm(id_ex_imm),
        .id_ex_rs1(id_ex_rs1),
        .id_ex_rs2(id_ex_rs2),
        .id_ex_rd(id_ex_rd),
        
        // Forwarding logic
        .forward_a(forward_a),
        .forward_b(forward_b),
        .forward_ex_mem_data(ex_mem_alu_result),
        .forward_mem_wb_data(wb_write_data),
        
        // Output back to IF
        .branch_target_addr(branch_target_addr),
        .pc_src(pc_src),
        
        // Pipeline EX/MEM outputs
        .ex_mem_reg_write(ex_mem_reg_write),
        .ex_mem_result_src(ex_mem_result_src),
        .ex_mem_mem_write(ex_mem_mem_write),
        .ex_mem_mem_read(ex_mem_mem_read),
        .ex_mem_alu_result(ex_mem_alu_result),
        .ex_mem_write_data(ex_mem_write_data),
        .ex_mem_rd(ex_mem_rd),
        .ex_mem_pc_plus_4(ex_mem_pc_plus_4)
    );

    // =========================================================================
    // MEM Stage
    // =========================================================================
    mem_stage mem_inst (
        .clk(clk),
        .reset_n(reset_n),
        
        // EX/MEM inputs
        .ex_mem_reg_write(ex_mem_reg_write),
        .ex_mem_result_src(ex_mem_result_src),
        .ex_mem_mem_write(ex_mem_mem_write),
        .ex_mem_mem_read(ex_mem_mem_read),
        .ex_mem_alu_result(ex_mem_alu_result),
        .ex_mem_write_data(ex_mem_write_data),
        .ex_mem_rd(ex_mem_rd),
        .ex_mem_pc_plus_4(ex_mem_pc_plus_4),
        
        // To memory interface
        .dmem_addr(dmem_addr),
        .dmem_wdata(dmem_wdata),
        .dmem_we(dmem_we),
        .dmem_re(dmem_re),
        .dmem_rdata(dmem_rdata),
        
        // MEM/WB Pipeline registers
        .mem_wb_reg_write(mem_wb_reg_write),
        .mem_wb_result_src(mem_wb_result_src),
        .mem_wb_alu_result(mem_wb_alu_result),
        .mem_wb_read_data(mem_wb_read_data),
        .mem_wb_rd(mem_wb_rd),
        .mem_wb_pc_plus_4(mem_wb_pc_plus_4)
    );

    // =========================================================================
    // WB Stage
    // =========================================================================
    wb_stage wb_inst (
        .mem_wb_result_src(mem_wb_result_src),
        .mem_wb_alu_result(mem_wb_alu_result),
        .mem_wb_read_data(mem_wb_read_data),
        .mem_wb_pc_plus_4(mem_wb_pc_plus_4),
        .wb_result(wb_write_data)
    );

endmodule
