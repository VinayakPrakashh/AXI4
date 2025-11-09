`timescale 1ns / 1ps

module uart_top_tb;

    parameter CLK_FREQ = 50000000;
    parameter BAUD_RATE = 9600;
    localparam BIT_PERIOD = 1_000_000_000 / BAUD_RATE;

    reg clk;
    reg resetn;
    reg uart_enable;
    reg uart_start;
    reg [7:0] uart_data_in;
    wire [7:0] uart_data_out;
    wire uart_tx;
    wire uart_busy;
    wire uart_done;
    wire uart_error;
    wire parity_error;
    wire framing_error;

    // Instantiate DUT
    uart_top #(
        .CLK_FREQ(CLK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) dut (
        .clk(clk),
        .resetn(resetn),
        .uart_enable(uart_enable),
        .uart_start(uart_start),
        .uart_data_in(uart_data_in),
        .uart_data_out(uart_data_out),
        .uart_tx(uart_tx),
        .uart_busy(uart_busy),
        .uart_done(uart_done),
        .uart_error(uart_error),
        .parity_error(parity_error),
        .framing_error(framing_error)
    );

    // Clock generation
    initial clk = 0;
    always #10 clk = ~clk; // 50 MHz

    // Test sequence
    initial begin
        // Initialization
        resetn = 0;
        uart_enable = 0;
        uart_start = 0;
        uart_data_in = 8'h00;

        #(200);
        resetn = 1;
        #(100);

        // Start UART loopback test
        uart_enable = 1;
        uart_data_in = 8'h55; // 10100101
        $display("Time %0t: Transmitting 0x%h ...", $time, uart_data_in);

        uart_start = 1;
        #(40);
        uart_start = 0;

        wait(uart_done);
        #(BIT_PERIOD * 2);

        if (uart_data_out == uart_data_in)
            $display("Time %0t: ? Loopback success! Received 0x%h", $time, uart_data_out);
        else
            $display("Time %0t: ? Loopback failed. Got 0x%h", $time, uart_data_out);

        if (uart_error)
            $display("UART Error detected!");
        else
            $display("UART Frame OK");

        #(1000);
        $finish;
    end

endmodule
