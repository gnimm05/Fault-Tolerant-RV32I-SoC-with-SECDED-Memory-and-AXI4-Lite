`timescale 1ns / 1ps

module ex_stage (
    input  logic        clk,
    input  logic        reset_n,
    
    // Control in
    input  logic        id_ex_alu_src_a,
    input  logic        id_ex_alu_src_b,
    input  logic [3:0]  id_ex_alu_control,
    input  logic        id_ex_mem_write,
    input  logic        id_ex_mem_read,
    input  logic [1:0]  id_ex_result_src,
    input  logic        id_ex_branch,
    input  logic        id_ex_jump,
    input  logic        id_ex_reg_write,
    input  logic [2:0]  id_ex_funct3, // Used for branch condition
    
    // Data in
    input  logic [31:0] id_ex_pc,
    input  logic [31:0] id_ex_read_data1,
    input  logic [31:0] id_ex_read_data2,
    input  logic [31:0] id_ex_imm,
    input  logic [4:0]  id_ex_rs1,
    input  logic [4:0]  id_ex_rs2,
    input  logic [4:0]  id_ex_rd,

    // Forwarding in
    input  logic [1:0]  forward_a,
    input  logic [1:0]  forward_b,
    input  logic [31:0] forward_ex_mem_data,
    input  logic [31:0] forward_mem_wb_data,

    // Output to IF
    output logic [31:0] branch_target_addr,
    output logic        pc_src,
    
    // EX/MEM outputs
    output logic        ex_mem_reg_write,
    output logic [1:0]  ex_mem_result_src,
    output logic        ex_mem_mem_write,
    output logic        ex_mem_mem_read,
    output logic [31:0] ex_mem_alu_result,
    output logic [31:0] ex_mem_write_data,
    output logic [4:0]  ex_mem_rd,
    output logic [31:0] ex_mem_pc_plus_4
);

    logic [31:0] src_a, src_b, alu_result;
    logic [31:0] fwd_data1, fwd_data2;
    logic zero, less, less_u;
    logic branch_cond;

    // Forwarding MUX for src A
    always_comb begin
        case(forward_a)
            2'b00: fwd_data1 = id_ex_read_data1;
            2'b01: fwd_data1 = forward_mem_wb_data;
            2'b10: fwd_data1 = forward_ex_mem_data;
            default: fwd_data1 = id_ex_read_data1;
        endcase
    end

    // Forwarding MUX for src B
    always_comb begin
        case(forward_b)
            2'b00: fwd_data2 = id_ex_read_data2;
            2'b01: fwd_data2 = forward_mem_wb_data;
            2'b10: fwd_data2 = forward_ex_mem_data;
            default: fwd_data2 = id_ex_read_data2;
        endcase
    end

    // ALU Mux
    assign src_a = id_ex_alu_src_a ? id_ex_pc : fwd_data1;
    assign src_b = id_ex_alu_src_b ? id_ex_imm : fwd_data2;

    // Branch Target
    assign branch_target_addr = id_ex_pc + id_ex_imm;

    // ALU
    always_comb begin
        alu_result = 32'b0;
        case (id_ex_alu_control)
            4'b0000: alu_result = src_a + src_b; // ADD
            4'b1000: alu_result = src_a - src_b; // SUB
            4'b0001: alu_result = src_a << src_b[4:0]; // SLL
            4'b0010: alu_result = ($signed(src_a) < $signed(src_b)) ? 32'b1 : 32'b0; // SLT
            4'b0011: alu_result = (src_a < src_b) ? 32'b1 : 32'b0; // SLTU
            4'b0100: alu_result = src_a ^ src_b; // XOR
            4'b0101: alu_result = src_a >> src_b[4:0]; // SRL
            4'b1101: alu_result = $signed(src_a) >>> src_b[4:0]; // SRA
            4'b0110: alu_result = src_a | src_b; // OR
            4'b0111: alu_result = src_a & src_b; // AND
            4'b1111: alu_result = src_b; // BYPASS B
            default: alu_result = 32'b0;
        endcase
    end

    // Branch logic flags
    assign zero = (src_a == src_b);
    assign less = ($signed(src_a) < $signed(src_b));
    assign less_u = (src_a < src_b);

    always_comb begin
        case (id_ex_funct3)
            3'b000: branch_cond = zero; // BEQ
            3'b001: branch_cond = !zero; // BNE
            3'b100: branch_cond = less;  // BLT
            3'b101: branch_cond = !less; // BGE
            3'b110: branch_cond = less_u; // BLTU
            3'b111: branch_cond = !less_u; // BGEU
            default: branch_cond = 1'b0;
        endcase
    end

    // Jump/Branch Decision
    assign pc_src = id_ex_jump | (id_ex_branch & branch_cond);

    // EX/MEM Pipeline Register
    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            ex_mem_reg_write  <= 1'b0;
            ex_mem_result_src <= 2'b0;
            ex_mem_mem_write  <= 1'b0;
            ex_mem_mem_read   <= 1'b0;
            ex_mem_alu_result <= 32'b0;
            ex_mem_write_data <= 32'b0;
            ex_mem_rd         <= 5'b0;
            ex_mem_pc_plus_4  <= 32'b0;
        end else begin
            ex_mem_reg_write  <= id_ex_reg_write;
            ex_mem_result_src <= id_ex_result_src;
            ex_mem_mem_write  <= id_ex_mem_write;
            ex_mem_mem_read   <= id_ex_mem_read;
            ex_mem_alu_result <= alu_result;
            // Write data shouldn't be overridden by immediate if it's store
            ex_mem_write_data <= fwd_data2; 
            ex_mem_rd         <= id_ex_rd;
            ex_mem_pc_plus_4  <= id_ex_pc + 32'd4;
        end
    end

endmodule
