module uart_tx #(
    parameter CLK_FREQ = 50000000, // 50 MHz
    parameter BAUD_RATE = 9600
) (
    input clk,
    input resetn,
    input tx_enable,
    input [7:0] tx_data,
    input tx_start,
    output reg tx,
    output reg tx_busy,
    output reg tx_done
);

reg [15:0] counter;
reg baud_tick;
reg parity_bit;

localparam IDLE = 3'b000,
           START_BIT = 3'b001,
           DATA_BITS = 3'b010,
           PARITY_BIT = 3'b011,
           STOP_BIT = 3'b100;
localparam BAUD_COUNTER_MAX = CLK_FREQ / BAUD_RATE;
reg [2:0] state;
reg [3:0] bit_index;
reg [7:0] tx_shift_reg;
always @(posedge clk or negedge resetn) begin
    if(!resetn) begin
        state <= IDLE;
        tx <= 1'b1; // Idle state is high
        tx_busy <= 1'b0;
        tx_done <= 1'b0;
        counter <= 16'd0;
        bit_index <= 4'd0;
        tx_shift_reg <= 8'd0;
    end
    else begin
        case(state)
        IDLE: begin
            tx <= 1'b1;
            tx_busy <= 1'b0;
            tx_done <= 1'b0;
            counter <= 16'd0;
            bit_index <= 4'd0;
            if(tx_enable && tx_start) begin
                tx_shift_reg <= tx_data;
                parity_bit <= ^tx_data; // Even parity
                state <= START_BIT;
                tx_busy <= 1'b1;
                tx <= 1'b0; // Start bit
            end

        end
        START_BIT: begin
            if(counter < BAUD_COUNTER_MAX - 1) begin
                counter <= counter + 1;
            end
            else begin
                counter <= 16'd0;
                state <= DATA_BITS;
                bit_index <= 4'd0;
                tx <= tx_shift_reg[bit_index];
            end
        end
        DATA_BITS: begin
            tx <= tx_shift_reg[bit_index];
            if(counter < BAUD_COUNTER_MAX - 1) begin
                counter <= counter + 1;
            end
            else begin
                counter <= 16'd0;
                
                if(bit_index < 7) begin
                    bit_index <= bit_index + 1;
                end
                else begin
                    state <= PARITY_BIT;
                    tx <= parity_bit;
                end
            end
        end
        PARITY_BIT: begin
            if(counter < BAUD_COUNTER_MAX - 1) begin
                counter <= counter + 1;
            end
            else begin
                counter <= 16'd0;
                state <= STOP_BIT;
                tx <= 1'b1; // Stop bit
            end
        end
        STOP_BIT: begin
            if(counter < BAUD_COUNTER_MAX - 1) begin
                counter <= counter + 1;
            end
            else begin
                counter <= 16'd0;
                state <= IDLE;
                tx_busy <= 1'b0;
                tx_done <= 1'b1;
            end
        end
        endcase
    end
end
endmodule