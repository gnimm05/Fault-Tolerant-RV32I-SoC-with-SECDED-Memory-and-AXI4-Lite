`timescale 1ns / 1ps

module if_stage_tb;

    // Inputs
    logic        clk;
    logic        reset_n;
    logic        pc_src;
    logic [31:0] branch_target_addr;

    // Outputs
    logic [31:0] instruction_address;
    logic [31:0] pc_plus_4;

    // Instantiate the Unit Under Test (UUT)
    if_stage uut (
        .clk(clk), 
        .reset_n(reset_n), 
        .pc_src(pc_src), 
        .branch_target_addr(branch_target_addr), 
        .instruction_address(instruction_address), 
        .pc_plus_4(pc_plus_4)
    );

    // Clock generation
    always #5 clk = ~clk;

    initial begin
        // Initialize Inputs
        clk = 0;
        reset_n = 0;
        pc_src = 0;
        branch_target_addr = 0;

        // Wait 100 ns for global reset to finish
        #100;
        
        // Release reset
        reset_n = 1;
        #10;
        
        // Test PC increment
        if (instruction_address !== 32'h00000000) $error("Test 1 Failed: PC should be 0 after reset");
        #10;
        if (instruction_address !== 32'h00000004) $error("Test 2 Failed: PC should increment by 4");
        #10;
        if (instruction_address !== 32'h00000008) $error("Test 3 Failed: PC should increment by 4");
        
        // Test Branching
        branch_target_addr = 32'h00001000;
        pc_src = 1;
        #10;
        if (instruction_address !== 32'h00001000) $error("Test 4 Failed: PC should jump to branch target");
        
        // Back to normal increment
        pc_src = 0;
        #10;
        if (instruction_address !== 32'h00001004) $error("Test 5 Failed: PC should increment by 4 from branch target");

        $display("if_stage tests completed.");
        $finish;
    end
      
endmodule
