module APB_slave1 #(
    parameter ADDR_WIDTH = 10,
    parameter DATA_WIDTH = 32
) (
    input PCLK,
    input PRESETn,
    // APB Slave Interface
    input PSEL_S1,
    input PENABLE_S,
    input read,
    input write,
    input [ADDR_WIDTH-1:0] PADDR_S,
    input [DATA_WIDTH-1:0] PWDATA_S,
    output reg [DATA_WIDTH-1:0] PRDATA_S,
    output reg PREADY_S
);

// Simple memory array for APB slave
reg [DATA_WIDTH-1:0] memory_array [0:1];
initial begin
    memory_array[0] = 32'h00000001;
    memory_array[1] = 32'h00000010;
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

 wire write_en, read_en, ready;


assign write_en = PSEL_S1 & PENABLE_S & write;
assign read_en  = PSEL_S1 & PENABLE_S & read;
assign ready = ~uart_tx_busy && PENABLE_S;
always @(posedge PCLK or negedge PRESETn ) begin
    PREADY_S <= ready;

    if (!PRESETn) begin
        PRDATA_S <= {DATA_WIDTH{1'b0}};
    end else if(read_en && ready) begin
            PRDATA_S <= memory_array[PADDR_S[1:0]];
        end
    else if(write_en && ready) begin
            memory_array[PADDR_S[1:0]] <= PWDATA_S;
            end

end

endmodule
