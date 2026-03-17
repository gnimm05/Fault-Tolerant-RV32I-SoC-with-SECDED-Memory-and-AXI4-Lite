`timescale 1ns / 1ps

module imm_gen_tb;

    // Inputs
    logic [31:0] instr;

    // Outputs
    logic [31:0] imm_out;

    // Instantiate the Unit Under Test (UUT)
    imm_gen uut (
        .instr(instr), 
        .imm_out(imm_out)
    );

    initial begin
        // Initialize Inputs
        instr = 0;
        #10;
        
        // I-Type (ADDI x5, x0, -1) -> opcode: 0010011, rd: 00101, rs1: 00000, funct3: 000, imm: 111111111111
        // instr = imm(11:0) | rs1 | funct3 | rd | opcode
        instr = {12'hFFF, 5'b00000, 3'b000, 5'b00101, 7'b0010011};
        #10;
        if (imm_out !== 32'hFFFFFFFF) $error("I-Type Immediate decode failed");
        
        // S-Type (SW x5, 4(x6)) -> opcode: 0100011, imm1: 0000000, rs2: 00101, rs1: 00110, funct3: 010, imm2: 00100
        instr = {7'b0000000, 5'd5, 5'd6, 3'b010, 5'd4, 7'b0100011};
        #10;
        if (imm_out !== 32'h00000004) $error("S-Type Immediate decode failed");

        // B-Type (BEQ x5, x6, -4) -> opcode: 1100011, imm: 1111111111100 (half-word aligned)
        // imm[12]=1, imm[10:5]=111111, rs2=6, rs1=5, funct3=0, imm[4:1]=1110, imm[11]=1
        instr = {1'b1, 6'b111111, 5'd6, 5'd5, 3'b000, 4'b1110, 1'b1, 7'b1100011};
        #10;
        if (imm_out !== 32'hFFFFFFFC) $error("B-Type Immediate decode failed");
        
        // U-Type (LUI x5, 0x12345) -> opcode: 0110111, rd: 00101, imm: 0x12345
        instr = {20'h12345, 5'd5, 7'b0110111};
        #10;
        if (imm_out !== 32'h12345000) $error("U-Type LUI Immediate decode failed");

        // J-Type (JAL x1, 0x800) -> 0x800 = 2048
        // imm[20]=0, imm[10:1]=1000000000, imm[11]=0, imm[19:12]=00000000
        instr = {1'b0, 10'b1000000000, 1'b0, 8'b00000000, 5'b00001, 7'b1101111};
        #10;
        if (imm_out !== 32'h00000800) $error("J-Type Immediate decode failed");

        $display("imm_gen tests completed.");
        $finish;
    end
      
endmodule
