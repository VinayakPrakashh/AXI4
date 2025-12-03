`timescale 1ns / 1ps

module AXI4_lite_simple_write_tb();

    // Parameters
    parameter CLK_PERIOD = 10;

    // Essential testbench signals
    reg ACLK;
    reg ARESETn;
    
    // AXI Write - only what's needed
    reg [31:0] AWADDR;
    reg AWVALID;
    wire AWREADY;
    reg [31:0] WDATA;
    reg WVALID;
    wire WREADY;
    reg [3:0] WSTRB;
    
    // Write Response - minimal
    wire [1:0] BRESP;
    wire BVALID;
    reg BREADY;
    
    // APB signals we care about
    wire write;
    wire [31:0] apb_waddr;
    wire [31:0] apb_wdata;
    reg apb_done;

    // DUT instantiation - tie off unused signals
    AXI4_lite dut (
        .ACLK(ACLK),
        .ARESETn(ARESETn),
        // AXI Write
        .AWADDR(AWADDR),
        .AWVALID(AWVALID),
        .AWREADY(AWREADY),
        .WDATA(WDATA),
        .WVALID(WVALID),
        .WREADY(WREADY),
        .WSTRB(WSTRB),
        .BRESP(BRESP),
        .BVALID(BVALID),
        .BREADY(BREADY),
        // AXI Read - tied off
        .ARADDR(32'h0),
        .ARVALID(1'b0),
        .ARREADY(),
        .RDATA(),
        .RVALID(),
        .RREADY(1'b0),
        .RRESP(),
        // APB Interface
        .transfer(),
        .read(),
        .write(write),
        .PSTRB(),
        .apb_waddr(apb_waddr),
        .apb_raddr(),
        .apb_wdata(apb_wdata),
        .apb_rdata(32'h0),
        .err_flag(1'b0),
        .apb_done(apb_done),
        .error()
    );

    // Clock generation
    initial begin
        ACLK = 0;
        forever #(CLK_PERIOD/2) ACLK = ~ACLK;
    end

    // Simple APB response
    always @(posedge ACLK) begin
        if (!ARESETn) begin
            apb_done <= 1'b0;
        end else begin
            if (write) begin
                #20;  // Wait 2 cycles
                apb_done <= 1'b1;
                #10;  // Hold for 1 cycle
                apb_done <= 1'b0;
            end
        end
    end

    // Simple test
    initial begin
        // Initialize
        ARESETn = 0;
        AWADDR = 0;
        AWVALID = 0;
        WDATA = 0;
        WVALID = 0;
        WSTRB = 0;
        BREADY = 1;  // Always ready for response
        apb_done = 0;

        // Reset
        #50;
        ARESETn = 1;
        #20;

        // Single write
        $display("Writing 0xDEADBEEF to address 0x1000");
        AWADDR = 32'h1000;
        WDATA = 32'hDEADBEEF;
        WSTRB = 4'b1111;
        AWVALID = 1;
        WVALID = 1;
        
        // Wait for acceptance
        wait(AWREADY && WREADY);
        #10;
        AWVALID = 0;
        WVALID = 0;
        
        // Wait for completion
        wait(BVALID);
        #10;
        
        $display("Write completed");
        #50;
        $finish;
    end

    // Simple monitor
    initial begin
        $monitor("Time=%0t | AWVALID=%b | WVALID=%b | write=%b | apb_addr=0x%h | apb_data=0x%h", 
                 $time, AWVALID, WVALID, write, apb_waddr, apb_wdata);
    end

endmodule