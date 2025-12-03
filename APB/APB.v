module APB_MASTER #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
) (
    input PCLK,
    input PRESETn,
    // APB Master Interface
    output PSEL_UART,
    output PSEL_TIMER,
    output reg PENABLE,
    output reg PWRITE,
    output reg [ADDR_WIDTH-1:0] PADDR,
    output reg [DATA_WIDTH-1:0] PWDATA,
    output reg [3:0] PSTRB,
    input [DATA_WIDTH-1:0] PRDATA,
    input PREADY,
    input PSLVERR,
    // Control signals AXI4 to APB
    input transfer,
    input read,
    input write,
    input [3:0] WSTRB,
    // axi4 inputs for simulation purposes
    input [ADDR_WIDTH-1:0] apb_waddr,
    input [ADDR_WIDTH-1:0] apb_raddr,
    input [DATA_WIDTH-1:0] apb_wdata,
    output reg [DATA_WIDTH-1:0] apb_rdata,
    output apb_done
);

wire error;
wire UART, TIMER;
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
    IDLE: begin
        if (transfer) // Start condition
            next_state = SETUP;
        else
            next_state = IDLE;
    end
    SETUP:
        next_state = ACCESS;
    ACCESS: begin
        if (PREADY && !transfer)
            next_state = IDLE;
        else if(PREADY && transfer)
            next_state = SETUP;
        else
            next_state = ACCESS;
    end
    endcase
end

always @(state) begin
 case (state)
    IDLE: begin
        PENABLE <= 1'b0;
        PSTRB <= 4'b0000;
    end 
    SETUP: begin

        PSTRB <= WSTRB;
        if(write) begin
            PWRITE <= 1'b1;
            PADDR <= apb_waddr;
            PWDATA <= apb_wdata;
        end else if(read) begin
            PWRITE <= 1'b0;
            PADDR <= apb_raddr;
        end
    end
    ACCESS: begin
        PENABLE <= 1'b1;
        if(!PWRITE && PREADY) begin
            apb_rdata <= PRDATA;
        end
    end
    default: begin

        PENABLE <= 1'b0;
        PSTRB <= 4'b0000;
    end
 endcase
    end

assign apb_done = ((PSEL_UART | PSEL_TIMER) && PENABLE && PREADY);
assign PSEL_UART  =(apb_waddr[ADDR_WIDTH-1:ADDR_WIDTH-4] == 0) ? 1'b1 : 1'b0;
assign PSEL_TIMER =(apb_waddr[ADDR_WIDTH-1:ADDR_WIDTH-4] > 0) ? 1'b1 : 1'b0;
assign error = PSLVERR & (PSEL_UART | PSEL_TIMER) & PENABLE; //just for future use
endmodule