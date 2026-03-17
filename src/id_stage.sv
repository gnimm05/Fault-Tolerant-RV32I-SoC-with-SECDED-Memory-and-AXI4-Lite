`timescale 1ns / 1ps

module id_stage (
    input  logic        clk,
    input  logic        reset_n,
    input  logic        flush,
    input  logic        stall,
    
    // From IF
    input  logic [31:0] if_id_pc,
    input  logic [31:0] if_id_instr,
    
    // Writeback interface (from WB)
    input  logic        wb_reg_write,
    input  logic [4:0]  wb_write_reg,
    input  logic [31:0] wb_write_data,
    
    // Outputs to EX Pipeline Register
    output logic [31:0] id_ex_pc,
    output logic [31:0] id_ex_read_data1,
    output logic [31:0] id_ex_read_data2,
    output logic [31:0] id_ex_imm,
    output logic [4:0]  id_ex_rs1,
    output logic [4:0]  id_ex_rs2,
    output logic [4:0]  id_ex_rd,
    
    // Control signals to EX/MEM/WB
    output logic        id_ex_alu_src_a,
    output logic        id_ex_alu_src_b,
    output logic [3:0]  id_ex_alu_control,
    output logic        id_ex_mem_write,
    output logic        id_ex_mem_read,
    output logic [1:0]  id_ex_result_src,
    output logic        id_ex_branch,
    output logic        id_ex_jump,
    output logic        id_ex_reg_write,
    output logic [2:0]  id_ex_funct3,
    
    output logic [31:0] read_data1_out, // bypassed to hazardous branch resolution if needed
    output logic [31:0] read_data2_out
);

    logic [4:0] rs1, rs2, rd;
    logic [6:0] opcode;
    logic [2:0] funct3;
    logic       funct7_5;
    
    assign rs1      = if_id_instr[19:15];
    assign rs2      = if_id_instr[24:20];
    assign rd       = if_id_instr[11:7];
    assign opcode   = if_id_instr[6:0];
    assign funct3   = if_id_instr[14:12];
    assign funct7_5 = if_id_instr[30];
    
    logic [31:0] read_data1, read_data2, imm_out;
    logic alu_src_a, alu_src_b, mem_write, mem_read, branch, jump, reg_write;
    logic [1:0] result_src;
    logic [3:0] alu_control;
    
    register_file rf (
        .clk(clk),
        .reset_n(reset_n),
        .we(wb_reg_write),
        .read_reg1(rs1),
        .read_reg2(rs2),
        .write_reg(wb_write_reg),
        .write_data(wb_write_data),
        .read_data1(read_data1),
        .read_data2(read_data2)
    ); // NOTE: register write is typically done on falling edge or with bypassing in forwarding to avoid data hazard.
    
    assign read_data1_out = read_data1;
    assign read_data2_out = read_data2;
    
    imm_gen ig (
        .instr(if_id_instr),
        .imm_out(imm_out)
    );
    
    control_unit cu (
        .opcode(opcode),
        .funct3(funct3),
        .funct7_5(funct7_5),
        .reg_write(reg_write),
        .alu_src_a(alu_src_a),
        .alu_src_b(alu_src_b),
        .mem_write(mem_write),
        .mem_read(mem_read),
        .result_src(result_src),
        .branch(branch),
        .jump(jump),
        .alu_control(alu_control)
    );
    
    // ID/EX Pipeline Register
    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            id_ex_pc          <= 32'b0;
            id_ex_read_data1  <= 32'b0;
            id_ex_read_data2  <= 32'b0;
            id_ex_imm         <= 32'b0;
            id_ex_rs1         <= 5'b0;
            id_ex_rs2         <= 5'b0;
            id_ex_rd          <= 5'b0;
            id_ex_alu_src_a   <= 1'b0;
            id_ex_alu_src_b   <= 1'b0;
            id_ex_alu_control <= 4'b0;
            id_ex_mem_write   <= 1'b0;
            id_ex_mem_read    <= 1'b0;
            id_ex_result_src  <= 2'b0;
            id_ex_branch      <= 1'b0;
            id_ex_jump        <= 1'b0;
            id_ex_reg_write   <= 1'b0;
            id_ex_funct3      <= 3'b0;
        end else if (flush) begin
            id_ex_pc          <= 32'b0;
            id_ex_read_data1  <= 32'b0;
            id_ex_read_data2  <= 32'b0;
            id_ex_imm         <= 32'b0;
            id_ex_rs1         <= 5'b0;
            id_ex_rs2         <= 5'b0;
            id_ex_rd          <= 5'b0;
            id_ex_alu_src_a   <= 1'b0;
            id_ex_alu_src_b   <= 1'b0;
            id_ex_alu_control <= 4'b0;
            id_ex_mem_write   <= 1'b0;
            id_ex_mem_read    <= 1'b0;
            id_ex_result_src  <= 2'b0;
            id_ex_branch      <= 1'b0;
            id_ex_jump        <= 1'b0;
            id_ex_reg_write   <= 1'b0;
            id_ex_funct3      <= 3'b0;
        end else if (!stall) begin
            id_ex_pc          <= if_id_pc;
            id_ex_read_data1  <= read_data1;
            id_ex_read_data2  <= read_data2;
            id_ex_imm         <= imm_out;
            id_ex_rs1         <= rs1;
            id_ex_rs2         <= rs2;
            id_ex_rd          <= rd;
            id_ex_alu_src_a   <= alu_src_a;
            id_ex_alu_src_b   <= alu_src_b;
            id_ex_alu_control <= alu_control;
            id_ex_mem_write   <= mem_write;
            id_ex_mem_read    <= mem_read;
            id_ex_result_src  <= result_src;
            id_ex_branch      <= branch;
            id_ex_jump        <= jump;
            id_ex_reg_write   <= reg_write;
            id_ex_funct3      <= funct3;
        end
    end

endmodule
