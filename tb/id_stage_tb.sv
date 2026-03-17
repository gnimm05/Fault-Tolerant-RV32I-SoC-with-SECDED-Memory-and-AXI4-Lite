`timescale 1ns / 1ps

module id_stage_tb;

    // Inputs
    logic        clk;
    logic        reset_n;
    logic        flush;
    logic        stall;
    logic [31:0] if_id_pc;
    logic [31:0] if_id_instr;
    logic        wb_reg_write;
    logic [4:0]  wb_write_reg;
    logic [31:0] wb_write_data;

    // Outputs
    logic [31:0] id_ex_pc;
    logic [31:0] id_ex_read_data1;
    logic [31:0] id_ex_read_data2;
    logic [31:0] id_ex_imm;
    logic [4:0]  id_ex_rs1;
    logic [4:0]  id_ex_rs2;
    logic [4:0]  id_ex_rd;
    logic        id_ex_alu_src_a;
    logic        id_ex_alu_src_b;
    logic [3:0]  id_ex_alu_control;
    logic        id_ex_mem_write;
    logic        id_ex_mem_read;
    logic [1:0]  id_ex_result_src;
    logic        id_ex_branch;
    logic        id_ex_jump;
    logic        id_ex_reg_write;
    logic [2:0]  id_ex_funct3;
    logic [31:0] read_data1_out;
    logic [31:0] read_data2_out;

    // Instantiate UUT
    id_stage uut (
        .clk(clk),
        .reset_n(reset_n),
        .flush(flush),
        .stall(stall),
        .if_id_pc(if_id_pc),
        .if_id_instr(if_id_instr),
        .wb_reg_write(wb_reg_write),
        .wb_write_reg(wb_write_reg),
        .wb_write_data(wb_write_data),
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
        .read_data1_out(read_data1_out),
        .read_data2_out(read_data2_out)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        reset_n = 0;
        flush = 0;
        stall = 0;
        if_id_pc = 32'h1000;
        if_id_instr = 32'h0;
        wb_reg_write = 0;
        wb_write_reg = 0;
        wb_write_data = 0;

        #20;
        reset_n = 1;

        // Give it an instruction: ADDI x5, x0, 10
        // opcode=0010011, rd=00101, funct3=000, rs1=00000, imm=000000001010
        if_id_instr = {12'h00A, 5'h00, 3'b000, 5'h05, 7'b0010011};
        #10;
        
        // Check output on pipeline boundary
        if (id_ex_rd !== 5'h05) $error("id_stage Pipeline RD output failed");
        if (id_ex_imm !== 32'hA) $error("id_stage Pipeline IMM output failed");
        if (id_ex_reg_write !== 1'b1) $error("id_stage Pipeline reg_write failed");
        
        // Test Stall
        stall = 1;
        if_id_instr = {12'h00B, 5'h00, 3'b000, 5'h06, 7'b0010011}; // ADDI x6, x0, 11
        #10;
        if (id_ex_rd !== 5'h05) $error("id_stage Stall failed: changed pipeline outputs");
        stall = 0;
        #10;
        if (id_ex_rd !== 5'h06) $error("id_stage Stall release failed");

        // Test Flush
        flush = 1;
        #10;
        if (id_ex_reg_write !== 0 || id_ex_rd !== 0) $error("id_stage Flush failed");

        $display("id_stage tests completed.");
        $finish;
    end
endmodule
