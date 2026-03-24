`timescale 1ns / 1ps

module secded_controller #(
    parameter MEM_SIZE = 1024
) (
    input  logic        clk,
    input  logic        reset_n,
    
    // CPU/AXI Interface
    input  logic [31:0] addr,
    input  logic [31:0] wdata,
    input  logic        we,
    input  logic        re,
    output logic [31:0] rdata,
    
    // Status flags
    output logic        single_error,
    output logic        double_error
);

    // 39-bit SRAM memory array with SECDED encoded packets
    logic [38:0] sram [0:MEM_SIZE-1];
    
    logic [38:0] encoded_write_data;
    logic [38:0] raw_read_data;
    logic [31:0] word_index;

    assign word_index = addr[31:2];

    // Encode data on the way into SRAM
    secded_encoder encoder (
        .data_in(wdata),
        .encoded_data(encoded_write_data)
    );

    // Synchronous write
    always_ff @(posedge clk) begin
        if (we) begin
            sram[word_index] <= encoded_write_data;
        end
    end

    // Asynchronous read for integration simplicity
    assign raw_read_data = sram[word_index];

    // Decode and Correct data on the way out
    secded_decoder decoder (
        .encoded_data(raw_read_data),
        .data_out(rdata),
        .single_error(single_error),
        .double_error(double_error)
    );

endmodule
