`timescale 1ns / 1ps

module APB_TOP_one_write_tb();

    // Testbench signals
    reg PCLK;
    reg PRESETn;
    reg transfer;
    reg read;
    reg write;
    reg [3:0] WSTRB;
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
        .WSTRB(WSTRB),
        .apb_waddr(apb_waddr),
        .apb_raddr(apb_raddr),
        .apb_wdata(apb_wdata),
        .apb_rdata(apb_rdata),
        .error(error)
    );

    // Clock generation
    initial begin
        PCLK = 0;
        forever #5 PCLK = ~PCLK;
    end

    // Test sequence
    initial begin
        // Initialize
        PRESETn = 0;
        transfer = 0;
        read = 0;
        write = 0;
        WSTRB = 4'b0000;
        apb_waddr = 0;
        apb_raddr = 0;
        apb_wdata = 0;

        // Reset
        #50;
        PRESETn = 1;
        #20;

        // Write data to TX Data Register
        $display("Writing 0xA5 to TX Data Register (0x00)");
        apb_waddr = 32'h00000000;    // TX Data Register address
        apb_wdata = 32'h000000A5;    // Write data 0xA5
        WSTRB = 4'b0001;             // WSTRB value as requested
        write = 1;
        transfer = 1;
        #20;
        transfer = 0;
        write = 0;
        WSTRB = 4'b0000;
        #50;

        // Write control data to Control Register
        $display("Writing 0x05 to Control Register (0x08)");
        apb_waddr = 32'h00000008;    // Control Register address (0x08)
        apb_wdata = 32'h00000005;    // Write control data 0x05
        WSTRB = 4'b0001;             // WSTRB value as requested
        write = 1;
        transfer = 1;
        #20;
        transfer = 0;
        write = 0;
        WSTRB = 4'b0000;
        #50;

        $display("Both writes completed:");
        $display("- TX Data: 0xA5 written to address 0x00");
        $display("- Control: 0x05 written to address 0x08");
        $finish;
    end

    // Simple monitor
    initial begin
        $monitor("Time=%0t | Addr=0x%h | Data=0x%h | Write=%b | WSTRB=0x%h | Error=%b", 
                 $time, apb_waddr, apb_wdata, write, WSTRB, error);
    end

    // Waveforms
    initial begin
        $dumpfile("one_write.vcd");
        $dumpvars(0, APB_TOP_one_write_tb);
    end

endmodule