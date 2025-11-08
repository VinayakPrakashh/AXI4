`timescale 1ns / 1ps

module APB_TOP_simple_tb();

    // Parameters
    parameter CLK_PERIOD = 10;

    // Testbench signals
    reg PCLK;
    reg PRESETn;
    reg transfer;
    reg read;
    reg write;
    reg [31:0] apb_waddr;
    reg [31:0] apb_raddr;
    reg [31:0] apb_wdata;
    wire [31:0] apb_rdata;
    wire error;

    // DUT instantiation
    APB_TOP dut (
        .PCLK(PCLK),
        .PRESETn(PRESETn),
        .transfer(transfer),
        .read(read),
        .write(write),
        .apb_waddr(apb_waddr),
        .apb_raddr(apb_raddr),
        .apb_wdata(apb_wdata),
        .apb_rdata(apb_rdata),
        .error(error)
    );

    // Clock generation
    initial begin
        PCLK = 0;
        forever #(CLK_PERIOD/2) PCLK = ~PCLK;
    end

    // Test sequence
    initial begin
        // Initialize
        PRESETn = 0;
        transfer = 0;
        read = 0;
        write = 0;
        apb_waddr = 0;
        apb_raddr = 0;
        apb_wdata = 0;

        $display("Starting APB TOP Simple Test");

        // Reset
        #50;
        PRESETn = 1;
        #20;

        // Test 1: Write to Slave 0
        $display("Test 1: Write to Slave 0");
        apb_waddr = 32'h00000010;  // Slave 0 address
        apb_wdata = 32'hDEADBEEF;
        write = 1;
        transfer = 1;
        #20;
        transfer = 0;
        write = 0;
        #50;

        // Test 2: Write to Slave 1
        $display("Test 2: Write to Slave 1");
        apb_waddr = 32'h00000110;  // Slave 1 address  
        apb_wdata = 32'hCAFEBABE;
        write = 1;
        transfer = 1;
        #20;
        transfer = 0;
        write = 0;
        #50;

        // Test 3: Read from Slave 0
        $display("Test 3: Read from Slave 0");
        apb_raddr = 32'h00000010;
        read = 1;
        transfer = 1;
        #20;
        transfer = 0;
        read = 0;
        #50;

        $display("Test completed");
        $finish;
    end

    // Monitor
    initial begin
        $monitor("Time=%0t | Write=%b | Read=%b | Addr=0x%h | WData=0x%h | RData=0x%h | Error=%b", 
                 $time, write, read, write ? apb_waddr : apb_raddr, apb_wdata, apb_rdata, error);
    end

    // Dump waveforms
    initial begin
        $dumpfile("apb_simple.vcd");
        $dumpvars(0, APB_TOP_simple_tb);
    end

endmodule