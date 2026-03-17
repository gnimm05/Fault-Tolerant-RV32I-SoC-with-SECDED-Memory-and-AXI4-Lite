`timescale 1ns / 1ps

module control_unit_tb;

    // Inputs
    logic [6:0] opcode;
    logic [2:0] funct3;
    logic       funct7_5;

    // Outputs
    logic       reg_write;
    logic       alu_src_a;
    logic       alu_src_b;
    logic       mem_write;
    logic       mem_read;
    logic [1:0] result_src;
    logic       branch;
    logic       jump;
    logic [3:0] alu_control;

    // Instantiate UUT
    control_unit uut (
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

    initial begin
        // R-Type ADD
        opcode = 7'b0110011; funct3 = 3'b000; funct7_5 = 1'b0;
        #10;
        if (reg_write !== 1 || alu_src_b !== 0 || mem_write !== 0 || alu_control !== 4'b0000)
            $error("R-Type ADD failed");

        // R-Type SUB
        opcode = 7'b0110011; funct3 = 3'b000; funct7_5 = 1'b1;
        #10;
        if (alu_control !== 4'b1000)
            $error("R-Type SUB failed");

        // I-Type ADDI
        opcode = 7'b0010011; funct3 = 3'b000; funct7_5 = 1'b0;
        #10;
        if (reg_write !== 1 || alu_src_b !== 1 || alu_control !== 4'b0000)
            $error("I-Type ADDI failed");

        // Load (LW)
        opcode = 7'b0000011; funct3 = 3'b010; funct7_5 = 1'b0;
        #10;
        if (reg_write !== 1 || alu_src_b !== 1 || mem_read !== 1 || result_src !== 2'b01)
            $error("LW failed");

        // Store (SW)
        opcode = 7'b0100011; funct3 = 3'b010; funct7_5 = 1'b0;
        #10;
        if (mem_write !== 1 || alu_src_b !== 1 || reg_write !== 0)
            $error("SW failed");

        // Branch (BEQ)
        opcode = 7'b1100011; funct3 = 3'b000; funct7_5 = 1'b0;
        #10;
        if (branch !== 1 || alu_control !== 4'b1000 || reg_write !== 0)
            $error("BEQ failed");

        // JAL
        opcode = 7'b1101111; funct3 = 3'b000; funct7_5 = 1'b0;
        #10;
        if (jump !== 1 || reg_write !== 1 || result_src !== 2'b10)
            $error("JAL failed");
            
        // LUI
        opcode = 7'b0110111; funct3 = 3'b000; funct7_5 = 1'b0;
        #10;
        if (reg_write !== 1 || alu_src_b !== 1 || alu_control !== 4'b1111)
            $error("LUI failed");

        $display("control_unit tests completed.");
        $finish;
    end
endmodule
