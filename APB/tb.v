`timescale 1ns / 1ps

module APB_TOP_single_write_tb();

    // Clock and Reset
    reg PCLK;
    reg PRESETn;
    
    // AXI Write signals
    reg  [31:0] AWADDR;
    reg         AWVALID;
    wire        AWREADY;
    reg  [31:0] WDATA;
    reg         WVALID;
    wire        WREADY;
    reg  [3:0]  WSTRB;
    wire [1:0]  BRESP;
    wire        BVALID;
    reg         BREADY;

    // AXI Read signals
    reg  [31:0] ARADDR;
    reg         ARVALID;
    wire        ARREADY;
    wire [31:0] RDATA;
    wire        RVALID;
    reg         RREADY;
    wire [1:0]  RRESP;

    // DUT
    APB_TOP dut (
        .PCLK   (PCLK),
        .PRESETn(PRESETn),
        .ACLK   (PCLK),
        .ARESETn(PRESETn),
        
        // AXI Write
        .AWADDR (AWADDR),
        .AWVALID(AWVALID),
        .AWREADY(AWREADY),
        .WDATA  (WDATA),
        .WVALID (WVALID),
        .WREADY (WREADY),
        .WSTRB  (WSTRB),
        .BRESP  (BRESP),
        .BVALID (BVALID),
        .BREADY (BREADY),
        
        // AXI Read
        .ARADDR (ARADDR),
        .ARVALID(ARVALID),
        .ARREADY(ARREADY),
        .RDATA  (RDATA),
        .RVALID (RVALID),
        .RREADY (RREADY),
        .RRESP  (RRESP),
        
        .error()
    );

    // Clock
    initial begin
        PCLK = 0;
        forever #5 PCLK = ~PCLK;   // 100 MHz
    end

    // BREADY control - goes high only after 125ns
    initial begin
        BREADY = 0;
        #125;
        BREADY = 1;
        $display("Time=%0t: BREADY asserted", $time);
    end

    // Test sequence: reset -> write -> read-back
    initial begin
        // Initialize
        PRESETn = 0;
        AWADDR  = 0;
        AWVALID = 0;
        WDATA   = 0;
        WVALID  = 0;
        WSTRB   = 0;

        ARADDR  = 0;
        ARVALID = 0;
        RREADY  = 0;

        // Reset
        #50;
        PRESETn = 1;
        #20;

        // For read channel, keep RREADY high so we always accept read data
        RREADY = 1;

        // ==========================
        //        WRITE PHASE
        // ==========================
        $display("Time=%0t: Starting write transaction", $time);
        AWADDR  = 32'h00000000;
        WDATA   = 32'h000000A5;    // write A5 in lowest byte
        WSTRB   = 4'b0001;         // only byte [7:0]
        AWVALID = 1;
        WVALID  = 1;
        
        // Wait for address & data handshake
        wait(AWREADY && WREADY);
        $display("Time=%0t: Address and data accepted", $time);
        #10;
        AWVALID = 0;
        WVALID  = 0;
        
        // Wait for BVALID (response will be held until BREADY goes high)
        wait(BVALID);
        $display("Time=%0t: BVALID asserted, waiting for BREADY", $time);
        
        // Wait for response completion (BVALID & BREADY)
        wait(BVALID && BREADY);
        $display("Time=%0t: Write response completed, BRESP=0x%0h", $time, BRESP);

        // small delay before read
        #20;

        // ==========================
        //        READ PHASE
        // ==========================
        $display("Time=%0t: Starting read transaction", $time);
        ARADDR  = 32'h00000000;    // same location as write
        ARVALID = 1;

        // Wait for read address handshake
        wait(ARREADY);
        $display("Time=%0t: Read address accepted", $time);
        #10;
        ARVALID = 0;

        // Wait for read data valid
        wait(RVALID);
        $display("Time=%0t: RVALID asserted, RDATA=0x%08h, RRESP=0x%0h", 
                 $time, RDATA, RRESP);

        // Data check (expect 0x000000A5 if slave stores full 32b with WSTRB)
        if (RDATA === 32'h000000A5 && RRESP == 2'b00)
            $display("Time=%0t: READ-BACK PASS: data matches", $time);
        else
            $display("Time=%0t: READ-BACK FAIL: expected 0x000000A5, got 0x%08h, RRESP=0x%0h", 
                     $time, RDATA, RRESP);

        #20;
        $display("Write + Read-back test completed");
        $finish;
    end

    // Monitor key signals
    initial begin
        $monitor("Time=%0t | BVALID=%b BREADY=%b BRESP=0x%0h | RVALID=%b RREADY=%b RDATA=0x%08h RRESP=0x%0h", 
                 $time, BVALID, BREADY, BRESP, RVALID, RREADY, RDATA, RRESP);
    end

endmodule
