module APB_MASTER #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
) (
    input PCLK,
    input PRESETn,
    // APB Master Interface
    output reg PSEL,
    output reg PENABLE,
    output reg PWRITE,
    output reg [ADDR_WIDTH-1:0] PADDR,
    output reg [DATA_WIDTH-1:0] PWDATA,
    input [DATA_WIDTH-1:0] PRDATA,
    input PREADY,
    input PSLVERR,
    // Control signals
    input transfer,
    input read,
    input write,


);
reg [1:0] state, next_state;

parameter IDLE = 2'b00,
          SETUP = 2'b01,
          ACCESS = 2'b10;
always @(posedge PCLK) begin
    if (!PRESETn)
        state <= IDLE;
    else
        state <= next_state; 
end

always @(*) begin
    case (state)
    IDLE:
        if (transfer) // Start condition
            next_state = SETUP;
        else
            next_state = IDLE;
    SETUP:
        next_state = ACCESS;
    ACCESS:
        if (PREADY)
            next_state = IDLE;
        else
            next_state = ACCESS;
    endcase
end
endmodule