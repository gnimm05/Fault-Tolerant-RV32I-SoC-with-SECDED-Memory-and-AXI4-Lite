`timescale 1ns / 1ps

module wb_stage (
    // From MEM/WB Pipeline Register
    input  logic [1:0]  mem_wb_result_src,
    input  logic [31:0] mem_wb_alu_result,
    input  logic [31:0] mem_wb_read_data,
    input  logic [31:0] mem_wb_pc_plus_4,

    // To ID Stage (Register File)
    output logic [31:0] wb_result
);

    // Writeback MUX
    always_comb begin
        case (mem_wb_result_src)
            2'b00: wb_result = mem_wb_alu_result;
            2'b01: wb_result = mem_wb_read_data;
            2'b10: wb_result = mem_wb_pc_plus_4; // For JAL/JALR
            default: wb_result = mem_wb_alu_result;
        endcase
    end

endmodule
