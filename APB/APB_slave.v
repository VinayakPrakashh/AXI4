module APB_slave1 #(
    parameter ADDR_WIDTH = 10,
    parameter DATA_WIDTH = 32
) (
    input PCLK,
    input PRESETn,
    // APB Slave Interface
    input PSEL,
    input PENABLE,
    input PWRITE,
    input [ADDR_WIDTH-1:0] PADDR,
    input [DATA_WIDTH-1:0] PWDATA,
    output reg [DATA_WIDTH-1:0] PRDATA,
    output reg PREADY,
    output reg PSLVERR
);

// Simple memory array for APB slave
reg [DATA_WIDTH-1:0] memory_array [0:3];
initial begin
    memory_array[0] = 32'h00000001;
    memory_array[1] = 32'h00000010;
    memory_array[2] = 32'h00000100;
    memory_array[3] = 32'h00001000;
end
uart_tx #(
    .CLK_FREQ(50000000),
    .BAUD_RATE(9600)
) uart_inst (
    .clk(PCLK),
    .resetn(PRESETn),
    .tx_start(uart_tx_start),
    .tx_data(memory_array[0][7:0]),
    .tx(uart_tx),
    .tx_busy(uart_tx_busy)
);

always @(posedge PCLK) begin
    if (!PRESETn) begin
        PRDATA <= {DATA_WIDTH{1'b0}};
        PREADY <= 1'b0;
    end else begin
        if (PSEL && PENABLE) begin
            if (PWRITE) begin
                // Write operation
                memory_array[PADDR[1:0]] <= PWDATA;
                PREADY <= 1'b1;
                PSLVERR <= (PADDR[1:0] < 2'b10) ? 1'b0 : 1'b1; // Example error condition
            end else begin
                // Read operation
                PRDATA <= memory_array[PADDR[1:0]];
                PREADY <= 1'b1;
            end
        end else begin
            PREADY <= 1'b0;
        end
    end
end
endmodule
