`timescale 1ns / 1ps

module axi4_top_write_read_tb();

    // Clock and Reset
    reg PCLK;
    reg PRESETn;
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

    // DUT instantiation
    axi4_top dut (
        .PCLK(PCLK),
        .PRESETn(PRESETn),
        .ACLK(ACLK),
        .ARESETn(ARESETn),
        // Control interface
        .start(start),
        .write(write),
        .addr(addr),
        .wdata(wdata),
        .wstrb(wstrb),
        .busy(busy),
        .done(done),
        .rdata(rdata),
        .resp(resp)
    );

    // Clock generation (same clock for both domains)
    initial begin
        PCLK = 0;
        ACLK = 0;
        forever begin
            #5;
            PCLK = ~PCLK;
            ACLK = ~ACLK;
        end
    end

    // Test sequence
    initial begin
        // Initialize
        PRESETn = 0;
        ARESETn = 0;
        start = 0;
        write = 0;
        addr = 0;
        wdata = 0;
        wstrb = 0;

        $display("=== Starting AXI4_TOP Write-Read Test ===");

        // Reset
        #50;
        PRESETn = 1;
        ARESETn = 1;
        #20;

        // ==========================================
        // WRITE TRANSACTION
        // ==========================================
        $display("\n--- WRITE Transaction ---");
        addr = 32'h00000000;    // UART slave address
        wdata = 32'h000000A5;   // Write data
        wstrb = 4'b0001;        // Byte write
        write = 1;              // Write operation
         start = 1;  
        #10; // Let signals settle
        
        $display("Writing 0x%h to address 0x%h", wdata, addr);

        // Pulse start signal
        @(posedge ACLK);
        start = 0;
        write = 0;
        
        // Wait for write completion
        wait(done);
        @(posedge ACLK);
        
        $display("Write completed with response: 0x%h", resp);
        
        // Clear write signals
        write = 0;
        wdata = 0;
        wstrb = 0;
        
        #50; // Gap between transactions

        // ==========================================
        // READ TRANSACTION
        // ==========================================
        $display("\n--- READ Transaction ---");
        addr = 32'h00000000;    // Same address
        write = 0;              // Read operation
           start = 1;              // Start transaction
        #10; // Let signals settle
        
        $display("Reading from address 0x%h", addr);

        // Pulse start signal
        @(posedge ACLK);
        start = 0;              // Start transaction
        write = 0;
        
        // Wait for read completion
        wait(done);
        @(posedge ACLK);
        
        $display("Read completed with response: 0x%h", resp);
        $display("Read data: 0x%h", rdata);
        
        // Verify read data matches written data
        if(rdata[7:0] == 8'hA5) begin
            $display("\n*** TEST PASSED: Read data matches written data! ***");
        end else begin
            $display("\n*** TEST FAILED: Read data (0x%h) does not match written data (0xA5) ***", rdata[7:0]);
        end

        #50;
        $display("\n=== Test Completed ===");
        $finish;
    end

    // Enhanced monitoring
    initial begin
        $monitor("Time=%0t | start=%b | write=%b | busy=%b | done=%b | addr=0x%h | wdata=0x%h | rdata=0x%h | resp=0x%h", 
                 $time, start, write, busy, done, addr, wdata, rdata, resp);
    end

    // Waveform dump
    initial begin
        $dumpfile("axi4_top_write_read.vcd");
        $dumpvars(0, axi4_top_write_read_tb);
    end

    // Timeout protection
    initial begin
        #10000;
        $display("TIMEOUT: Test took too long!");
        $finish;
    end

endmodule