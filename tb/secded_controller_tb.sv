`timescale 1ns / 1ps

module secded_controller_tb;

    logic        clk;
    logic        reset_n;
    
    logic [31:0] addr;
    logic [31:0] wdata;
    logic        we;
    logic        re;
    wire  [31:0] rdata;
    wire         single_error;
    wire         double_error;

    // Instantiate Design Under Test
    secded_controller #(
        .MEM_SIZE(16)
    ) dut (
        .clk(clk),
        .reset_n(reset_n),
        .addr(addr),
        .wdata(wdata),
        .we(we),
        .re(re),
        .rdata(rdata),
        .single_error(single_error),
        .double_error(double_error)
    );

    // Clock generator
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Stimulus and self-check
    initial begin
        $display("Starting SECDED fault injection test...");
        
        // Reset Sequence
        reset_n = 0;
        addr    = 0;
        wdata   = 0;
        we      = 0;
        re      = 0;
        #15;
        reset_n = 1;
        
        // Action 1: Write a clean 32-bit word 
        @(posedge clk);
        addr  = 32'h04; // Word index 1
        wdata = 32'hDEADBEEF;
        we    = 1'b1;
        @(posedge clk);
        we    = 1'b0;
        
        // Validate normal read back
        @(posedge clk);
        re    = 1'b1;
        #1;
        if (rdata == 32'hDEADBEEF && !single_error && !double_error)
            $display("1. Normal Read OK");
        else
            $display("1. Normal Read FAILED: rdata=%h single=%b double=%b", rdata, single_error, double_error);
            
        // Action 2: Inject a Single-Bit Fault in memory
        @(posedge clk);
        re = 1'b0;
        // Flip bit 15 of word index 1 (SRAM[1])
        dut.sram[1] = dut.sram[1] ^ 39'h00_0000_8000; 
        
        @(posedge clk);
        re = 1'b1;
        #1;
        if (rdata == 32'hDEADBEEF && single_error && !double_error)
            $display("2. Corrected Read (Single Error Inject) OK");
        else
            $display("2. Corrected Read FAILED: rdata=%h single=%b double=%b", rdata, single_error, double_error);

        // Action 3: Inject a Second Fault in the same word (Double-Bit Error)
        @(posedge clk);
        re = 1'b0;
        // Flip bit 16 of word index 1 (Now both bit 15 and bit 16 are flipped)
        dut.sram[1] = dut.sram[1] ^ 39'h00_0001_0000; 
        
        @(posedge clk);
        re = 1'b1;
        #1;
        if (double_error && !single_error)
            $display("3. Double Error Detected OK");
        else
            $display("3. Double Error Detect FAILED: single=%b double=%b", single_error, double_error);

        #10;
        $display("Test complete.");
        $finish;
    end

endmodule
