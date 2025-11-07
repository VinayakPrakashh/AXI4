module APB_master #(
    parameter ADDR_WIDTH = 10,
    parameter DATA_WIDTH = 32

) (
    input PCLK,
    input PRESETn,
    // APB Master Interface
    input PSEL_1,
    input PSEL_2,
    input PENABLE,
    input PWRITE,
    input [ADDR_WIDTH-1:0] PADDR,
    input [DATA_WIDTH-1:0] PWDATA,
    output reg [DATA_WIDTH-1:0] PRDATA,
    output reg PREADY,
    // APB Slave Interface
    output PSEL_S1,
    output PSEL_S2,
    output reg PENABLE_S,
    output reg read,
    output reg write,
    output reg [ADDR_WIDTH-1:0] PADDR_S,
    output reg [DATA_WIDTH-1:0] PWDATA_S,
    input [DATA_WIDTH-1:0] PRDATA_S,
    input PREADY_S


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
        if (PSEL_1 | PSEL_2 ) // Start condition
            next_state = SETUP;
        else
            next_state = IDLE;
    SETUP:
        next_state = ACCESS;
    ACCESS:
        if (PREADY_S)
            next_state = IDLE;
        else
            next_state = ACCESS;
    endcase
end
always @(posedge PCLK ) begin
    if(!PRESETn) begin
        PREADY <=0;
        PENABLE_S <=0;
        PADDR_S <=0;
        PWDATA_S <=0;
        read <=0;
        write <=0;
        
    end
    else begin
    case (state)
    IDLE: begin
        PREADY <=0;
        PENABLE_S <=0;
        PADDR_S <=0;
        PWDATA_S <=0;
        read <=0;
        write <=0;
    end
    SETUP: begin
        PADDR_S <= PADDR;
        PWDATA_S <= PWDATA;
        if(PWRITE)
            write <=1;
        else
            read <=1;
    end
    ACCESS: begin
        PENABLE_S <=PENABLE;
        if (PREADY_S) begin
            PREADY <=1;
            PRDATA <= PRDATA_S;
        end
    end
    endcase
    end
end

assign {PSEL_S1,PSEL_S2} = (state == IDLE) ? 2'b00: {PSEL_1,PSEL_2};
endmodule