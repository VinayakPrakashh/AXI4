`timescale 1ns / 1ps

module axi4lite_master_simple_tb();

    // Clock and Reset
    reg ACLK;
    reg ARESETn;

    // Control Interface
    reg start;
    reg write;
    reg [31:0] addr;
    reg [31:0] wdata;
    reg [3:0] wstrb;
    wire busy;
    wire done;
    wire [31:0] rdata;
    wire [1:0] resp;

    // AXI4-Lite Interface
    wire [31:0] AWADDR;
    wire AWVALID;
    reg AWREADY;
    wire [31:0] WDATA;
    wire WVALID;
    reg WREADY;
    wire [3:0] WSTRB;
    reg [1:0] BRESP;
    reg BVALID;
    wire BREADY;

    // DUT
    axi4lite_master dut (
        .ACLK(ACLK),
        .ARESETn(ARESETn),
        // Control
        .start(start),
        .write(write),
        .addr(addr),
        .wdata(wdata),
        .wstrb(wstrb),
        .busy(busy),
        .done(done),
        .rdata(rdata),
        .resp(resp),
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
        // AXI Read (unused)
        .ARADDR(),
        .ARVALID(),
        .ARREADY(1'b0),
        .RDATA(32'h0),
        .RVALID(1'b0),
        .RREADY(),
        .RRESP(2'b00)
    );

    // Clock
    initial begin
        ACLK = 0;
        forever #5 ACLK = ~ACLK;
    end

    // Simple slave response
    always @(posedge ACLK) begin
        if (!ARESETn) begin
            AWREADY <= 1'b0;
            WREADY <= 1'b0;
            BVALID <= 1'b0;
        end else begin
            // Accept address and data immediately
            AWREADY <= AWVALID;
            WREADY <= WVALID;
            
            // Response after both accepted
            if (AWVALID && AWREADY && WVALID && WREADY) begin
                #10;
                BRESP <= 2'b00; // OKAY
                BVALID <= 1'b1;
            end
            
            // Clear response when accepted
            if (BVALID && BREADY) begin
                #10;
                BVALID <= 1'b0;
            end
        end
    end

    // Test
    initial begin
        // Initialize
        ARESETn = 0;
        start = 0;
        write = 0;
        addr = 0;
        wdata = 0;
        wstrb = 0;
        AWREADY = 0;
        WREADY = 0;
        BVALID = 0;
        BRESP = 0;

        // Reset
        #50;
        ARESETn = 1;
        #20;

        // Single write
        addr = 32'h1000_0000;
        wdata = 32'hDEADBEEF;
        wstrb = 4'b1111;
        write = 1;
        start = 1;
        
        // Pulse start
        #10;
        start = 0;
        write = 0;
        
        // Wait for completion
        wait(done);
        #20;
        
        $display("Write completed: RESP=0x%h", resp);
        $finish;
    end

    // Monitor
    initial begin
        $monitor("Time=%0t | State=%0d | busy=%b | AWVALID=%b | WVALID=%b | BVALID=%b | done=%b", 
                 $time, dut.state, busy, AWVALID, WVALID, BVALID, done);
    end

endmodule