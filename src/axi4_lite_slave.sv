`timescale 1ns / 1ps

module axi4_lite_slave (
    input  logic        clk,
    input  logic        reset_n,

    // AXI4-Lite Interface
    input  logic [31:0] awaddr,
    input  logic        awvalid,
    output logic        awready,

    input  logic [31:0] wdata,
    input  logic [3:0]  wstrb,
    input  logic        wvalid,
    output logic        wready,

    output logic [1:0]  bresp,
    output logic        bvalid,
    input  logic        bready,

    input  logic [31:0] araddr,
    input  logic        arvalid,
    output logic        arready,

    output logic [31:0] rdata,
    output logic [1:0]  rresp,
    output logic        rvalid,
    input  logic        rready,

    // Memory (SECDED Controller) Interface
    output logic [31:0] mem_addr,
    output logic [31:0] mem_wdata,
    output logic        mem_we,
    output logic        mem_re,
    input  logic [31:0] mem_rdata
);

    typedef enum logic [2:0] {
        IDLE,
        WRITE_DATA,
        WRITE_RESP,
        READ_DATA
    } state_t;

    state_t state, next_state;
    
    // Latched addresses
    logic [31:0] write_addr_reg;
    logic [31:0] read_addr_reg;

    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            state <= IDLE;
            write_addr_reg <= 32'b0;
            read_addr_reg  <= 32'b0;
        end else begin
            state <= next_state;
            if (awvalid && awready) write_addr_reg <= awaddr;
            if (arvalid && arready) read_addr_reg  <= araddr;
        end
    end

    always_comb begin
        next_state = state;
        
        // AXI defaults
        awready = 0;
        wready  = 0;
        bvalid  = 0;
        bresp   = 2'b00; // OKAY
        arready = 0;
        rvalid  = 0;
        rresp   = 2'b00; // OKAY
        rdata   = 32'b0;
        
        // Mem defaults
        mem_we    = 0;
        mem_re    = 0;
        mem_addr  = 32'b0;
        mem_wdata = 32'b0;

        case (state)
            IDLE: begin
                // Give priority to reads (arbitrary choice)
                if (arvalid) begin
                    arready = 1;
                    next_state = READ_DATA;
                end else if (awvalid) begin
                    awready = 1;
                    next_state = WRITE_DATA;
                end
            end

            WRITE_DATA: begin
                wready = 1;
                if (wvalid) begin
                    // Perform write to SECDED SRAM
                    mem_addr  = write_addr_reg;
                    mem_wdata = wdata;
                    mem_we    = 1;
                    next_state = WRITE_RESP;
                end
            end

            WRITE_RESP: begin
                bvalid = 1;
                if (bready) begin
                    next_state = IDLE;
                end
            end

            READ_DATA: begin
                // Ask SRAM to read
                mem_addr = read_addr_reg;
                mem_re   = 1;
                rdata    = mem_rdata; // Fetch data
                rvalid   = 1;
                if (rready) begin
                    next_state = IDLE;
                end
            end
            
            default: next_state = IDLE;
        endcase
    end

endmodule
