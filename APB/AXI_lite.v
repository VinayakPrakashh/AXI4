module AXI4_lite #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32

) (
    input ACLK,
    input ARESETn,
    //AXI READ
    input [ADDR_WIDTH-1:0] ARADDR,
    input ARVALID,
    output reg ARREADY,
    output reg [DATA_WIDTH-1:0] RDATA,
    output reg RVALID,
    input RREADY,
    output reg  [1:0] RRESP,
    //AXI WRITE
    input [ADDR_WIDTH-1:0] AWADDR,
    input AWVALID,
    output reg AWREADY,
    input [DATA_WIDTH-1:0] WDATA,
    input WVALID,
    output reg WREADY,
    input [3:0] WSTRB,
    // WRITE RESPONSE
    output reg[1:0] BRESP,
    output reg BVALID,
    input BREADY,
    // Error signal
    output error,
    //for APB TOP module
    output reg transfer,
    output reg read,
    output reg write,

    output  [3:0] PSTRB,
    output  [ADDR_WIDTH-1:0] apb_waddr,
    output [ADDR_WIDTH-1:0] apb_raddr,
    output  [DATA_WIDTH-1:0] apb_wdata,
    input [DATA_WIDTH-1:0] apb_rdata,
    input err_flag,
    input apb_done

);

localparam S_IDLE   = 3'd0,
           S_W_REQ  = 3'd1,
           S_W_WAIT = 3'd2,
           S_W_RESP = 3'd3,
           S_R_REQ  = 3'd4,
           S_R_WAIT = 3'd5,
           S_R_RESP = 3'd6,
           S_R_INT  = 3'd7;


reg [2:0] state, next_state;
reg [ADDR_WIDTH-1:0] latched_araddr;
reg [ADDR_WIDTH-1:0] latched_awaddr;
reg  [DATA_WIDTH-1:0] latched_wdata;
reg  [3:0] latched_wstrb;
always @(posedge ACLK) begin
    if (!ARESETn)
        state <= S_IDLE;
    else
        state <= next_state; 
end
always @(posedge ACLK ) begin
    if((state == S_IDLE) && AWVALID && WVALID) begin
        latched_awaddr <= AWADDR;
        latched_wdata  <= WDATA;
        latched_wstrb  <= WSTRB;
    end
    else if(ARVALID) begin
        latched_araddr <= ARADDR;
    end
end
always @(*) begin
    case (state)

    S_IDLE: begin
        if(AWVALID && WVALID)
            next_state = S_W_REQ;
        else if(ARVALID)
            next_state = S_R_REQ;
        else
            next_state = S_IDLE;
    end
    S_W_REQ: begin
        next_state = S_W_WAIT;
    end
    S_R_REQ: begin
        next_state = S_R_WAIT;
    end
    S_W_WAIT: begin
            if(apb_done) begin
            next_state = S_W_RESP;
        end
    end
    S_R_WAIT: begin
        if(apb_done) begin
            next_state = S_R_INT;
        end
    end
    S_R_INT: begin
        next_state = S_R_RESP;
    end
    S_W_RESP: begin
        if (BREADY)
            next_state = S_IDLE;
        else
            next_state = S_W_RESP;
    end
    S_R_RESP: begin
        if (RREADY)
            next_state = S_IDLE;
        else
            next_state = S_R_RESP;
    end
    default: begin
        next_state = S_IDLE;
    end
    endcase
end

always @(posedge ACLK) begin
    case (state)
    S_IDLE: begin
        //WRITE CHANNEL
        AWREADY <= 1'b0;
        WREADY  <= 1'b0;
        BVALID  <= 1'b0;
        //READ CHANNEL
        ARREADY <= 1'b0;
        RVALID  <= 1'b0;

        //APB signals
        transfer <= 1'b0;
        read     <= 1'b0;
        write    <= 1'b0;

        if(AWVALID && WVALID) begin
            AWREADY <= 1'b1;
            WREADY  <= 1'b1;
            transfer <= 1'b1;
            write    <= 1'b1;
        end
        else if(ARVALID) begin
            ARREADY <= 1'b1;
            transfer <= 1'b1;
            read     <= 1'b1;
        end
    end
    S_W_REQ: begin
        AWREADY    <= 1'b0;
        WREADY     <= 1'b0;

        transfer    <= 1'b0;
        write       <= 1'b0;

    end
    S_R_REQ: begin
        ARREADY    <= 1'b0;
        transfer    <= 1'b0;
        read        <= 1'b0;

    end
    S_W_WAIT: begin
        BVALID <= 1'b1;
        write <= 1'b0;

    end
    S_R_WAIT: begin
        read <= 1'b0;
    end
    S_W_RESP: begin

            BRESP  <= err_flag ? 2'b10 : 2'b00; // 10=SLVERR, 00=OKAY

            if(BREADY) begin
                BVALID <= 1'b0;
            end
        end
    S_R_INT: begin
                    RVALID <= 1'b1;
        end
    S_R_RESP: begin

            RDATA  <= apb_rdata;
            RRESP  <= err_flag ? 2'b10 : 2'b00; // 10=SLVERR, 00=OKAY

            if(RREADY) begin
                RVALID <= 1'b0;
            end
        end
    default: begin
        AWREADY <= 1'b0;
        WREADY  <= 1'b0;
        BVALID  <= 1'b0;
        ARREADY <= 1'b0;
        RVALID  <= 1'b0;
        transfer <= 1'b0;
        read     <= 1'b0;
        write    <= 1'b0;
    end
endcase
end
assign apb_waddr = latched_awaddr;
assign apb_raddr = latched_araddr;
assign apb_wdata = latched_wdata;
assign PSTRB     = latched_wstrb; // Assuming full
endmodule