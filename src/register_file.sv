`timescale 1ns / 1ps

module register_file (
    input  logic        clk,
    input  logic        reset_n,
    input  logic        we,          // Write Enable
    input  logic [4:0]  read_reg1,   // rs1
    input  logic [4:0]  read_reg2,   // rs2
    input  logic [4:0]  write_reg,   // rd
    input  logic [31:0] write_data,
    
    output logic [31:0] read_data1,
    output logic [31:0] read_data2
);

    logic [31:0] registers [31:0];

    // Read logic (asynchronous read)
    assign read_data1 = (read_reg1 == 5'b0) ? 32'b0 : registers[read_reg1];
    assign read_data2 = (read_reg2 == 5'b0) ? 32'b0 : registers[read_reg2];

    // Write logic
    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            integer i;
            for (i = 1; i < 32; i = i + 1) begin
                registers[i] <= 32'b0;
            end
        end else begin
            if (we && write_reg != 5'b0) begin
                registers[write_reg] <= write_data;
            end
        end
    end

endmodule
