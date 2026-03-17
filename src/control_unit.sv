`timescale 1ns / 1ps

module control_unit (
    input  logic [6:0] opcode,
    input  logic [2:0] funct3,
    input  logic       funct7_5, // instr[30]
    
    output logic       reg_write,
    output logic       alu_src_a, // 0: rs1,   1: pc (for AUIPC)
    output logic       alu_src_b, // 0: rs2,   1: imm
    output logic       mem_write,
    output logic       mem_read,
    output logic [1:0] result_src, // 00: ALU, 01: Mem, 10: PC+4
    output logic       branch,
    output logic       jump,
    output logic [3:0] alu_control
);

    logic [1:0] alu_op;
    
    // Main Decoder
    always_comb begin
        // Defaults
        reg_write  = 1'b0;
        alu_src_a  = 1'b0;
        alu_src_b  = 1'b0;
        mem_write  = 1'b0;
        mem_read   = 1'b0;
        result_src = 2'b00;
        branch     = 1'b0;
        jump       = 1'b0;
        alu_op     = 2'b00;
        
        case(opcode)
            7'b0110011: begin // R-type
                reg_write = 1'b1;
                alu_op    = 2'b10;
            end
            7'b0010011: begin // I-type ALU
                reg_write = 1'b1;
                alu_src_b = 1'b1;
                alu_op    = 2'b10;
            end
            7'b0000011: begin // Load
                reg_write  = 1'b1;
                alu_src_b  = 1'b1;
                mem_read   = 1'b1;
                result_src = 2'b01;
                alu_op     = 2'b00; // ALU needs to add offset
            end
            7'b0100011: begin // Store
                alu_src_b = 1'b1;
                mem_write = 1'b1;
                alu_op    = 2'b00; // ALU needs to add offset
            end
            7'b1100011: begin // Branch
                branch = 1'b1;
                alu_op = 2'b01; // ALU needs to subtract for cmp
            end
            7'b1101111: begin // JAL
                reg_write  = 1'b1;
                jump       = 1'b1;
                result_src = 2'b10;
            end
            7'b1100111: begin // JALR
                reg_write  = 1'b1;
                alu_src_b  = 1'b1;
                jump       = 1'b1;
                result_src = 2'b10;
                alu_op     = 2'b00;
            end
            7'b0110111: begin // LUI
                reg_write = 1'b1;
                alu_src_b = 1'b1;
                alu_op    = 2'b11; // custom Bypass B
            end
            7'b0010111: begin // AUIPC
                reg_write = 1'b1;
                alu_src_a = 1'b1;
                alu_src_b = 1'b1;
                alu_op    = 2'b00; // ADD
            end
            default: ;
        endcase
    end
    
    // ALU Decoder
    always_comb begin
        if (alu_op == 2'b00) begin
            alu_control = 4'b0000; // ADD
        end else if (alu_op == 2'b01) begin
            alu_control = 4'b1000; // SUB
        end else if (alu_op == 2'b11) begin
            alu_control = 4'b1111; // BYPASS_B
        end else begin
            case(funct3)
                3'b000: begin
                    if (opcode[5] && funct7_5) alu_control = 4'b1000; // SUB
                    else alu_control = 4'b0000; // ADD
                end
                3'b001: alu_control = 4'b0001; // SLL
                3'b010: alu_control = 4'b0010; // SLT
                3'b011: alu_control = 4'b0011; // SLTU
                3'b100: alu_control = 4'b0100; // XOR
                3'b101: begin
                    if (funct7_5) alu_control = 4'b1101; // SRA
                    else alu_control = 4'b0101; // SRL
                end
                3'b110: alu_control = 4'b0110; // OR
                3'b111: alu_control = 4'b0111; // AND
            endcase
        end
    end
endmodule
