`timescale 1ns / 1ps

module secded_decoder (
    input  logic [38:0] encoded_data,
    output logic [31:0] data_out,
    output logic        single_error,
    output logic        double_error
);

    logic [38:0] word;
    logic [5:0]  syndrome;
    logic        overall_parity, expected_parity;
    integer i, j;

    always_comb begin
        word = encoded_data;
        
        // Calculate Syndrome
        syndrome = 6'b0;
        for (i = 1; i <= 38; i++) begin
            if (word[i]) begin
                syndrome = syndrome ^ i[5:0];
            end
        end

        overall_parity = ^word[38:1];
        expected_parity = word[0];

        single_error = 1'b0;
        double_error = 1'b0;

        if (syndrome != 6'b0) begin
            if (overall_parity != expected_parity) begin
                // Single Error Correctable
                single_error = 1'b1;
                if (syndrome <= 38) begin
                    word[syndrome] = ~word[syndrome]; // Correct flipped bit
                end
            end else begin
                // Double Error Unrecoverable
                double_error = 1'b1;
            end
        end else if (overall_parity != expected_parity) begin
            // Parity bit 0 is flipped (Single Error)
            single_error = 1'b1;
        end

        // Extract Data without parities
        j = 0;
        for (i = 1; i <= 38; i++) begin
            if (i != 1 && i != 2 && i != 4 && i != 8 && i != 16 && i != 32) begin
                data_out[j] = word[i];
                j++;
            end
        end
    end

endmodule
