`timescale 1ns / 1ps

module axi4_lite_master (
    input  logic        clk,
    input  logic        reset_n,

    // CPU Side Interface
    input  logic [31:0] cpu_addr,
    input  logic [31:0] cpu_wdata,
    input  logic        cpu_we,
    input  logic        cpu_re,
    output logic [31:0] cpu_rdata,
    output logic        cpu_ready, // Indicates transaction is complete

    // AXI4-Lite Write Address Channel
    output logic [31:0] awaddr,
    output logic        awvalid,
    input  logic        awready,

    // AXI4-Lite Write Data Channel
    output logic [31:0] wdata,
    output logic [3:0]  wstrb,
    output logic        wvalid,
    input  logic        wready,

    // AXI4-Lite Write Response Channel
    input  logic [1:0]  bresp,
    input  logic        bvalid,
    output logic        bready,

    // AXI4-Lite Read Address Channel
    output logic [31:0] araddr,
    output logic        arvalid,
    input  logic        arready,

    // AXI4-Lite Read Data Channel
    input  logic [31:0] rdata,
    input  logic [1:0]  rresp,
    input  logic        rvalid,
    output logic        rready
);

    typedef enum logic [2:0] {
        IDLE,
        WRITE_ADDR,
        WRITE_DATA,
        WRITE_RESP,
        READ_ADDR,
        READ_DATA
    } state_t;

    state_t state, next_state;

    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) state <= IDLE;
        else state <= next_state;
    end

    always_comb begin
        next_state = state;
        
        // Default AXI outputs
        awvalid = 0;
        wvalid  = 0;
        bready  = 0;
        arvalid = 0;
        rready  = 0;
        
        awaddr  = cpu_addr;
        wdata   = cpu_wdata;
        wstrb   = 4'b1111;
        araddr  = cpu_addr;

        // Default CPU outputs
        cpu_ready = 0;
        cpu_rdata = rdata;

        case (state)
            IDLE: begin
                if (cpu_we) begin
                    next_state = WRITE_ADDR;
                end else if (cpu_re) begin
                    next_state = READ_ADDR;
                end
            end

            WRITE_ADDR: begin
                awvalid = 1;
                if (awready) begin
                    next_state = WRITE_DATA;
                end
            end

            WRITE_DATA: begin
                wvalid = 1;
                if (wready) begin
                    next_state = WRITE_RESP;
                end
            end

            WRITE_RESP: begin
                bready = 1;
                if (bvalid) begin
                    cpu_ready = 1; // Transaction complete
                    next_state = IDLE;
                end
            end

            READ_ADDR: begin
                arvalid = 1;
                if (arready) begin
                    next_state = READ_DATA;
                end
            end

            READ_DATA: begin
                rready = 1;
                if (rvalid) begin
                    cpu_ready = 1; // Transaction complete
                    cpu_rdata = rdata;
                    next_state = IDLE;
                end
            end
            
            default: next_state = IDLE;
        endcase
    end

endmodule
