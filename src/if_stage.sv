`timescale 1ns / 1ps

module if_stage (
    input  logic        clk,
    input  logic        reset_n,
    input  logic        pc_src,
    input  logic [31:0] branch_target_addr,
    
    output logic [31:0] instruction_address,
    output logic [31:0] pc_plus_4
);

    logic [31:0] pc_reg;
    logic [31:0] next_pc;

    // PC Adder
    assign pc_plus_4 = pc_reg + 32'd4;

    // PC Multiplexer
    assign next_pc = (pc_src) ? branch_target_addr : pc_plus_4;

    // PC Register
    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            pc_reg <= 32'h00000000; // Boot address / Reset vector
        end else begin
            pc_reg <= next_pc;
        end
    end

    // Instruction Memory Address
    assign instruction_address = pc_reg;

endmodule
