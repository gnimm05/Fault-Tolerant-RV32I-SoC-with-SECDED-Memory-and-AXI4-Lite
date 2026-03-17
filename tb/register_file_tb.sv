`timescale 1ns / 1ps

module register_file_tb;

    // Inputs
    logic        clk;
    logic        reset_n;
    logic        we;
    logic [4:0]  read_reg1;
    logic [4:0]  read_reg2;
    logic [4:0]  write_reg;
    logic [31:0] write_data;

    // Outputs
    logic [31:0] read_data1;
    logic [31:0] read_data2;

    // Instantiate the Unit Under Test (UUT)
    register_file uut (
        .clk(clk), 
        .reset_n(reset_n), 
        .we(we), 
        .read_reg1(read_reg1), 
        .read_reg2(read_reg2), 
        .write_reg(write_reg), 
        .write_data(write_data), 
        .read_data1(read_data1), 
        .read_data2(read_data2)
    );

    // Clock generation
    always #5 clk = ~clk;

    initial begin
        // Initialize Inputs
        clk = 0;
        reset_n = 0;
        we = 0;
        read_reg1 = 0;
        read_reg2 = 0;
        write_reg = 0;
        write_data = 0;

        // Reset
        #20;
        reset_n = 1;
        #10;
        
        // Test writing to r0 (should stay 0)
        write_reg = 5'd0;
        write_data = 32'hDEADBEEF;
        we = 1;
        #10;
        we = 0;
        read_reg1 = 5'd0;
        #1;
        if (read_data1 !== 32'h0) $error("Test 1 Failed: x0 must always be 0");
        
        // Test writing to an arbitrary register x5
        write_reg = 5'd5;
        write_data = 32'h12345678;
        we = 1;
        #10;
        we = 0;
        read_reg2 = 5'd5;
        #1;
        if (read_data2 !== 32'h12345678) $error("Test 2 Failed: Did not read correct data from x5");
        
        // Test sequential reads
        write_reg = 5'd6;
        write_data = 32'h87654321;
        we = 1;
        #10;
        we = 0;
        
        read_reg1 = 5'd5;
        read_reg2 = 5'd6;
        #1;
        if (read_data1 !== 32'h12345678 || read_data2 !== 32'h87654321) $error("Test 3 Failed: Dual asynchronous read failed");

        $display("register_file tests completed.");
        $finish;
    end
      
endmodule
