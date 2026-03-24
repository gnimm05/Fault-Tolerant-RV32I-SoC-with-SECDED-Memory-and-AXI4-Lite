`timescale 1ns / 1ps

module secded_encoder (
    input  logic [31:0] data_in,
    output logic [38:0] encoded_data
);

    logic [38:0] word;
    logic [5:0]  parity;
    logic        overall_parity;
    integer i, j;
    
    always_comb begin
        // Map data to word length
        j = 0;
        for (i = 1; i <= 38; i++) begin
            if (i == 1 || i == 2 || i == 4 || i == 8 || i == 16 || i == 32) begin
                word[i] = 1'b0; // Parity placeholders
            end else begin
                word[i] = data_in[j];
                j++;
            end
        end

        // Calculate Parity P0 to P5
        parity = 6'b0;
        for (i = 1; i <= 38; i++) begin
            if (word[i]) begin
                parity = parity ^ i[5:0];
            end
        end

        // Substitute calculated parities
        word[1]  = parity[0];
        word[2]  = parity[1];
        word[4]  = parity[2];
        word[8]  = parity[3];
        word[16] = parity[4];
        word[32] = parity[5];

        // Overall parity for Double Error Detection
        overall_parity = ^word[38:1];
        word[0] = overall_parity;

        encoded_data = word;
    end

endmodule
