module uart_top #(
    parameter CLK_FREQ = 50000000,
    parameter BAUD_RATE = 9600
) (
    input clk,
    input resetn,
    input uart_enable,        // Common enable for TX/RX
    input uart_start,         // Common start for TX/RX
    input [7:0] uart_data_in, // Data to transmit
    output [7:0] uart_data_out, // Data received
    output uart_tx,           // TX line output
    output uart_busy,         // Common busy signal
    output uart_done,         // Common done signal
    output uart_error,        // Combined error signal
    output parity_error,
    output framing_error
);

    // Internal signals
    wire tx_busy, tx_done;
    wire rx_busy, rx_done;
    wire rx_error;

    // TX instance
    uart_tx #(
        .CLK_FREQ(CLK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) uart_tx_inst (
        .clk(clk),
        .resetn(resetn),
        .tx_enable(uart_enable),
        .tx_data(uart_data_in),
        .tx_start(uart_start),
        .tx(uart_tx),
        .tx_busy(tx_busy),
        .tx_done(tx_done)
    );

    // RX instance (loopback)
    uart_rx #(
        .CLK_FREQ(CLK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) uart_rx_inst (
        .clk(clk),
        .resetn(resetn),
        .rx_enable(uart_enable),
        .rx(uart_tx), // loopback
        .rx_data(uart_data_out),
        .rx_done(rx_done),
        .rx_error(rx_error),
        .rx_busy(rx_busy),
        .parity_error(parity_error),
        .framing_error(framing_error)
    );

    // Combined status signals
    assign uart_busy  = tx_busy | rx_busy;
    assign uart_done  = tx_done & rx_done;
    assign uart_error = rx_error | parity_error | framing_error;

endmodule
