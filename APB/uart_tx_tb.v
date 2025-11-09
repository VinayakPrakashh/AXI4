`timescale 1ns/1ps

module tb_uart_tx;

    // Parameters
    parameter CLK_FREQ   = 50_000_000; // 50 MHz clock
    parameter BAUD_RATE  = 9600;       // Standard UART baud
    parameter CLK_PERIOD = 20;         // 50MHz -> 20ns period

    // DUT I/O
    reg clk;
    reg resetn;
    reg tx_enable;
    reg [7:0] tx_data;
    reg tx_start;
    wire tx;
    wire tx_busy;
    wire tx_done;

    // Instantiate DUT (Design Under Test)
    uart_tx #(
        .CLK_FREQ(CLK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) DUT (
        .clk(clk),
        .resetn(resetn),
        .tx_enable(tx_enable),
        .tx_data(tx_data),
        .tx_start(tx_start),
        .tx(tx),
        .tx_busy(tx_busy),
        .tx_done(tx_done)
    );

    // Clock generation
    always #(CLK_PERIOD/2) clk = ~clk;

    // Simulation variables
    integer i;
    real baud_period_ns;

    initial begin
        // Calculate baud period in nanoseconds
        baud_period_ns = (1.0e9 / BAUD_RATE);
        $display("Baud Period = %0f ns", baud_period_ns);
    end

    // Test stimulus
    initial begin
        // Dump waveforms for GTKWave or ModelSim
        $dumpfile("uart_tx_tb.vcd");
        $dumpvars(0, tb_uart_tx);

        // Initialize signals
        clk = 0;
        resetn = 0;
        tx_enable = 0;
        tx_data = 8'h00;
        tx_start = 0;

        // Reset sequence
        #100;
        resetn = 1;
        tx_enable = 1;
        $display("RESET complete @ %0t ns", $time);

        // Transmit first byte (e.g., ASCII 'A' = 0x41)
        #200;
        tx_data = 8'b10000010;   // 'A'
        tx_start = 1;
        #20;
        tx_start = 0;
        $display("[%0t ns] Sending data = 0x%0h ('A')", $time, tx_data);

        // Wait for transmission to complete
        wait (tx_done);
        $display("[%0t ns] Transmission complete!", $time);

        // Send another character 'Z'
        #20000; // wait between bytes
        tx_data = 8'h5A;   // 'Z'
        tx_start = 1;
        #20;
        tx_start = 0;
        $display("[%0t ns] Sending data = 0x%0h ('Z')", $time, tx_data);
        wait (tx_done);
        $display("[%0t ns] Transmission complete!", $time);

        // End simulation
        #10000;
        $display("Simulation complete @ %0t ns", $time);
        $finish;
    end

    // Monitor key signals
    initial begin
        $display("Time (ns)\tTX\tBusy\tDone");
        $monitor("%0t\t%b\t%b\t%b", $time, tx, tx_busy, tx_done);
    end

endmodule
