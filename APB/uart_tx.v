module uart_tx #(
    parameter CLK_FREQ = 50000000, // 50 MHz
    parameter BAUD_RATE = 9600
) (
    input clk,
    input resetn,
    input tx_start,
    input [7:0] tx_data,
    output reg tx,
    output reg tx_busy
);
localparam BAUD_TICK_COUNT = CLK_FREQ / BAUD_RATE;
reg [15:0] baud_counter;
reg [3:0] bit_index;
reg [9:0] tx_shift_reg; // Start bit + 8 data bits +
                          // Stop bit   
always @(posedge clk or negedge resetn) begin
    if (!resetn) begin
        tx <= 1'b1; // Idle state
        tx_busy <= 1'b0;
        baud_counter <= 16'd0;
        bit_index <= 4'd0;
        tx_shift_reg <= 10'd0;
    end else begin
        if (tx_start && !tx_busy) begin
            // Load shift register with start, data, and stop bits
            tx_shift_reg <= {1'b1, tx_data, 1'b0}; // Stop bit, data, start bit
            tx_busy <= 1'b1;
            baud_counter <= 16'd0;
            bit_index <= 4'd0;
        end else if (tx_busy) begin
            if (baud_counter < BAUD_TICK_COUNT - 1) begin
                baud_counter <= baud_counter + 1;
            end else begin
                baud_counter <= 16'd0;
                tx <= tx_shift_reg[bit_index];
                bit_index <= bit_index + 1;
                if (bit_index == 4'd9) begin
                    tx_busy <= 1'b0; // Transmission complete
                end
            end
        end
    end
end

endmodule