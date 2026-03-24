`timescale 1ns / 1ps

module hazard_detection_unit (
    input  logic [4:0] id_rs1,
    input  logic [4:0] id_rs2,
    input  logic [4:0] id_ex_rd,
    input  logic       id_ex_mem_read,
    input  logic       pc_src, // branch or jump taken
    
    output logic       stall,
    output logic       flush_id_ex,
    output logic       flush_if_id
);

    always_comb begin
        stall       = 1'b0;
        flush_id_ex = 1'b0;
        flush_if_id = 1'b0;

        // 1. Load-Use Hazard
        if (id_ex_mem_read && ((id_ex_rd == id_rs1) || (id_ex_rd == id_rs2)) && (id_ex_rd != 5'b0)) begin
            stall       = 1'b1;  // stall IF and ID
            flush_id_ex = 1'b1;  // bubble ID/EX
        end
        // 2. Control Hazard (Branch/Jump Taken)
        else if (pc_src) begin
            flush_if_id = 1'b1;  // Flush the incorrectly fetched instructions
            flush_id_ex = 1'b1;
        end
    end

endmodule
