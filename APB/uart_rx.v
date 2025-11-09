module uart_rx #(
    parameter CLK_FREQ = 50000000, // 50 MHz
    parameter BAUD_RATE = 9600
) (
    input clk,
    input resetn,
    input rx_enable,
    input rx_start,
    input rx,
    output reg [7:0] rx_data,
    output reg rx_done,
    output reg rx_error,
    output reg rx_busy,
    output reg parity_error,
    output reg framing_error

);          
reg [15:0] counter;
reg parity_bit;
localparam IDLE = 3'b000,
           START_BIT = 3'b001,
           DATA_BITS = 3'b010,
           PARITY_BIT = 3'b011,
           STOP_BIT = 3'b100;
localparam BAUD_COUNTER_MAX = CLK_FREQ / BAUD_RATE;
reg [2:0] state;
reg [3:0] bit_index;
reg [7:0] rx_shift_reg;
always @(posedge clk or negedge resetn) begin
    if(!resetn)begin
        state <= IDLE;
        rx_data <= 8'd0;
        rx_done <= 1'b0;
        rx_error <= 1'b0;
        rx_busy <= 1'b0;
        parity_error <= 1'b0;
        framing_error <= 1'b0;
        counter <= 16'd0;
        bit_index <= 4'd0;
        rx_shift_reg <= 8'd0;
    end
    else case(state)
    IDLE: begin
        rx_done <= 1'b0;
        rx_error <= 1'b0;
        parity_error <= 1'b0;
        framing_error <= 1'b0;
        counter <= 16'd0;
        bit_index <= 4'd0;
        if(rx_enable && rx_start) begin
            state <= START_BIT;
            rx_busy <= 1'b1;
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
        end
    end
    DATA_BITS: begin
        if(counter < BAUD_COUNTER_MAX - 1) begin
            counter <= counter + 1;
        end
        else begin
            counter <= 16'd0;
            rx_shift_reg[bit_index] <= rx;
            bit_index <= bit_index + 1;
            if(bit_index == 7) begin
                state <= PARITY_BIT;
            end
        end
    end
    PARITY_BIT: begin
        if(counter < BAUD_COUNTER_MAX - 1) begin
            counter <= counter + 1;
        end
        else begin
            counter <= 16'd0;
            parity_bit <= rx;
            // Check parity (even parity)
            if(parity_bit != ^rx_shift_reg) begin
                parity_error <= 1'b1;
            end
            state <= STOP_BIT;
        end
        end
    STOP_BIT: begin
        if(counter < BAUD_COUNTER_MAX - 1) begin
            counter <= counter + 1;
        end
        else begin
            counter <= 16'd0;
            // Check stop bit
            if(rx != 1'b1) begin
                framing_error <= 1'b1;
            end
            rx_data <= rx_shift_reg;
            rx_done <= 1'b1;
            rx_busy <= 1'b0;
            state <= IDLE;
        end
    end
    endcase
    end


endmodule